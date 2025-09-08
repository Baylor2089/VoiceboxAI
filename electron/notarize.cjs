// Notarize the app after signing if Apple credentials are present
const { notarize } = require('@electron/notarize');

exports.default = async function notarizeHook(context) {
  const { electronPlatformName, appOutDir, packager } = context;
  if (electronPlatformName !== 'darwin') return;

  const appleId = process.env.APPLE_ID;
  const appleIdPassword = process.env.APPLE_APP_SPECIFIC_PASSWORD;
  const teamId = process.env.APPLE_TEAM_ID;

  if (!appleId || !appleIdPassword || !teamId) {
    console.log('[notarize] Apple credentials missing; skip notarization.');
    return;
  }

  const appName = packager.appInfo.productFilename;
  const appPath = `${appOutDir}/${appName}.app`;

  console.log(`[notarize] Notarizing ${appPath}`);
  await notarize({
    appBundleId: packager.appInfo.config.appId,
    appPath,
    appleId,
    appleIdPassword,
    teamId
  });
  console.log('[notarize] Done');
};

