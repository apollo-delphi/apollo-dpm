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
  cKeyBinaryFileRefs = 'binaryFileRefs';
  cKeyBplFileRef = 'bplFileRef';
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
  cKeyProjectFileRefs = 'projectFileRefs';
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
  cStrAtLeastOnePackageShouldBeAdded = 'At least one package reference should be added!';
  cStrAtLeastOneProjectShouldBeAdded = 'At least one project reference should be added!';
  cStrCantLoadTheRepositoryURL = 'Can`t load the repository URL!';
  cStrLatestVersionOrCommit = 'the latest version or commit';
  cStrLatestCommit = 'the latest commit';
  cStrMustHaveBplExtension = 'Package file name must have .bpl extension';
  cStrMustHaveDprojExtension = 'Project file name must have .dproj extension';
  cStrNotDesignTimePackage = 'can''t be installed because it is not a design time package';
  cStrPackage = 'File name (.bpl)';
  cStrProject = 'File name (.droj)';
  cStrTheFieldCantBeEmpty = 'The field can''t be empty!';
  cStrTheGitHubRepositoryUrlIsInvalid = 'The GitHub repository URL is invalid!';
  cStrVersionNotSelected = 'Version not selected!';

  cSwitchToLeftIconIndex = 0;
  cSwitchToRightIconIndex = 1;

  cValidationLoadRepoData = 'ValidationLoadRepoData';
  cValidationOKClick = 'ValidationOKClick';

implementation

end.
