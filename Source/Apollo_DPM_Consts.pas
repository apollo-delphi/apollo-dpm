unit Apollo_DPM_Consts;

interface

uses
  Apollo_DPM_Package;

const
  cApolloMenuItemCaption = 'Apollo';
  cApolloMenuItemName = 'miApollo';

  cDPMMenuItemCaption = 'DPM - Delphi Package Manager...';

  cFilterListTypeNames: array [TFilterListType] of string = (
    'None',
    'Black List',
    'White List'
  );

  cPackageTypeNames: array [TPackageType] of string = (
    'Code Source',
    'Bpl Source',
    'Bpl Binary',
    'Project Template'
  );

  cKeyAdjustment = 'adjustment';
  cKeyBplBinaryFile = 'bplBinaryFile';
  cKeyBplProjectFile = 'bplProjectFile';
  cKeyDependencies = 'dependencies';
  cKeyDescription = 'description';
  cKeyDestination = 'destination';
  cKeyFilterList = 'filterList';
  cKeyFilterListType = 'filterListType';
  cKeyGHPAToken = 'GHPAToken';
  cKeyId = 'id';
  cKeyName = 'name';
  cKeyPackageType = 'packageType';
  cKeyPathMoves = 'pathMoves';
  cKeyRepoName = 'repoName';
  cKeyRepoOwner = 'repoOwner';
  cKeySource = 'source';
  cKeyVersion = 'version';
  cKeyVersionName = 'name';
  cKeyVersionSHA = 'sha';

  cNavInstalledToIDE = 'Installed to IDE';
  cNavPrivatePackages = 'Private Packages';
  cNavProjectDependencies = 'Project Dependencies';
  cNavSettings = 'Settings';

  cPathPrivatePackagesFolder = 'Apollo\DPM\PrivatePackages';
  cPathProjectPackages = 'DPM.Packages.json';
  cPathSettings = 'Apollo\DPM\DPM.Settings.json';

  cStrAPackageWithThisNameAlreadyExists = 'A package with this name already exists!';
  cStrARepositoryNameIsEmpty = 'A repository name is empty. Please go to GitHub URL!';
  cStrCantLoadTheRepositoryURL = 'Can`t load the repository URL!';
  cStrLatestVersionOrCommit = 'the latest version or commit';
  cStrLatestCommit = 'the latest commit';
  cStrMustHaveBplExtension = 'Bpl Options - Bpl Binary File must have .bpl extension';
  cStrMustHaveDprojExtension = 'Bpl Options - Bpl Project File must have .dproj extension';
  cStrTheFieldCannotBeEmpty = 'The field cannot be empty!';
  cStrTheGitHubRepositoryUrlIsInvalid = 'The GitHub repository URL is invalid!';
  cStrVersionNotSelected = 'Version not selected!';

  cSwitchToLeftIconIndex = 0;
  cSwitchToRightIconIndex = 1;

  cValidationLoadRepoData = 'ValidationLoadRepoData';
  cValidationOKClick = 'ValidationOKClick';

implementation

end.
