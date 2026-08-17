// SPDX-License-Identifier: GPL-3.0-or-later

/**
 * Publish release requests only after proving that their exact target commit is
 * part of main and has a successful Character Profiler iOS Build workflow run.
 *
 * Keeping this logic in a normal JavaScript file lets CI syntax-check it before
 * GitHub Script executes it, rather than hiding a large program inside YAML.
 */
module.exports = async ({ github, context, core }) => {
  const fs = require('fs');
  const path = require('path');

  const owner = context.repo.owner;
  const repo = context.repo.repo;
  const directory = '.github/release-requests';

  if (!fs.existsSync(directory)) {
    core.info('No release request directory exists.');
    return;
  }

  const requests = fs.readdirSync(directory)
    .filter((name) => name.endsWith('.json'))
    .sort();

  for (const filename of requests) {
    const requestPath = path.join(directory, filename);
    const request = JSON.parse(fs.readFileSync(requestPath, 'utf8'));

    if (!/^v[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$/.test(request.tag ?? '')) {
      throw new Error(`${filename}: invalid semantic-version tag.`);
    }

    if (!/^[0-9a-f]{40}$/i.test(request.target ?? '')) {
      throw new Error(`${filename}: target must be a full 40-character commit SHA.`);
    }

    const tag = request.tag;
    const target = request.target.toLowerCase();

    // A release must never tag an arbitrary side-branch commit. Comparing the
    // requested target to main proves that target is on main's ancestry.
    const comparison = await github.rest.repos.compareCommitsWithBasehead({
      owner,
      repo,
      basehead: `${target}...main`
    });
    if (comparison.data.merge_base_commit?.sha?.toLowerCase() !== target) {
      throw new Error(`${filename}: target ${target} is not an ancestor of main.`);
    }

    // Require a successful run for the exact target SHA. A green build on a
    // newer or older commit is not evidence that the release target is valid.
    const runs = await github.rest.actions.listWorkflowRunsForRepo({
      owner,
      repo,
      head_sha: target,
      status: 'completed',
      per_page: 100
    });
    const successfulIOSBuild = runs.data.workflow_runs.some((run) =>
      run.name === 'iOS Build' && run.head_sha?.toLowerCase() === target && run.conclusion === 'success'
    );
    if (!successfulIOSBuild) {
      throw new Error(`${filename}: target ${target} has no successful iOS Build workflow run.`);
    }

    try {
      const existingRef = await github.rest.git.getRef({ owner, repo, ref: `tags/${tag}` });
      if (existingRef.data.object.sha.toLowerCase() !== target) {
        throw new Error(`${tag} already exists but points to ${existingRef.data.object.sha}, not ${target}.`);
      }
      core.info(`${tag} already points to ${target}.`);
    } catch (error) {
      if (error.status !== 404) throw error;
      await github.rest.git.createRef({ owner, repo, ref: `refs/tags/${tag}`, sha: target });
      core.info(`Created ${tag} at ${target}.`);
    }

    try {
      const existingRelease = await github.rest.repos.getReleaseByTag({ owner, repo, tag });
      core.info(`Release ${tag} already exists: ${existingRelease.data.html_url}`);
    } catch (error) {
      if (error.status !== 404) throw error;
      const release = await github.rest.repos.createRelease({
        owner,
        repo,
        tag_name: tag,
        target_commitish: target,
        name: request.title ?? tag,
        body: request.notes ?? '',
        draft: Boolean(request.draft),
        prerelease: Boolean(request.prerelease)
      });
      core.info(`Published ${tag}: ${release.data.html_url}`);
    }
  }
};
