class AppStrings {
  // ── App ──────────────────────────────────────────────────
  static const String appName = 'DiagramAI';
  static const String appTagline = 'Sign in to your account';

  // ── Auth — Login ─────────────────────────────────────────
  static const String login = 'Sign in';
  static const String loginButton = 'Sign in';
  static const String loginGoogle = 'Continue with Google';
  static const String loginNoAccount = "No account?";
  static const String loginCreateOne = 'Create one';
  static const String forgotPassword = 'Forgot password?';

  // ── Auth — Register ──────────────────────────────────────
  static const String register = 'Create account';
  static const String registerSubtitle = 'Start building diagrams in minutes';
  static const String registerButton = 'Create account';
  static const String registerTerms = 'By signing up, you agree to our ';
  static const String registerTermsLink = 'Terms';
  static const String registerAnd = ' and ';
  static const String registerPrivacy = 'Privacy Policy';
  static const String registerHaveAccount = 'Already have an account?';
  static const String registerSignIn = 'Sign in';

  // ── Auth — Fields ────────────────────────────────────────
  static const String fieldFullName = 'Full name';
  static const String fieldEmail = 'Email';
  static const String fieldPassword = 'Password';
  static const String hintEmail = 'email@example.com';
  static const String hintFullName = 'Jane Doe';
  static const String hintPassword = '••••••••';

  // ── Password strength ────────────────────────────────────
  static const String passwordWeak = 'Weak password';
  static const String passwordFair = 'Fair password';
  static const String passwordGood = 'Good password';
  static const String passwordStrong = 'Strong password';

  // ── Projects ─────────────────────────────────────────────
  static const String projects = 'Projects';
  static const String newProject = '+ New project';
  static const String searchProjects = 'Search projects...';
  static const String createProject = 'Create project';
  static const String projectName = 'Project name';
  static const String projectDescription = 'Description';
  static const String hintProjectName = 'My App Database';
  static const String hintProjectDescription = 'Optional notes...';
  static const String cancel = 'Cancel';
  static const String create = 'Create';
  static const String diagramCount = 'diagrams';
  static const String updatedPrefix = 'Updated ';

  // ── Diagrams ─────────────────────────────────────────────
  static const String newDiagram = 'New diagram';
  static const String diagramType = 'Diagram type';
  static const String diagramName = 'Name';
  static const String diagramDescription = 'Describe your diagram';
  static const String generateDiagram = '✦ Generate diagram';
  static const String newDiagramButton = '+ New diagram';

  // ── Diagram types ────────────────────────────────────────
  static const String typeErd = 'ERD';
  static const String typeClass = 'Class';
  static const String typeMindMap = 'Mind Map';
  static const String typeAuto = 'Auto';

  // ── Diagram viewer ───────────────────────────────────────
  static const String preview = 'Preview';
  static const String mermaidCode = 'Mermaid code';
  static const String exportDiagram = '↓ Export';
  static const String editDiagram = '✎ Edit';

  // ── UX States ────────────────────────────────────────────
  static const String loading = 'Loading...';
  static const String generating = 'Generating...';
  static const String generatingSubtitle = 'AI is building your diagram';
  static const String emptyProjects = 'No projects yet';
  static const String emptyProjectsSubtitle = 'Create your first project to get started';
  static const String emptyDiagrams = 'No diagrams yet';
  static const String emptyDiagramsSubtitle = 'Generate your first diagram';
  static const String errorGeneric = 'Something went wrong';
  static const String errorGenerating = 'Could not generate diagram. Please try again.';
  static const String tryAgain = 'Try again';
  static const String createFirstProject = '+ Create project';

  // ── Navigation ───────────────────────────────────────────
  static const String navProjects = 'Projects';
  static const String navRecent = 'Recent';
  static const String navSettings = 'Settings';

  // ── Errors ───────────────────────────────────────────────
  static const String errorEmptyEmail = 'Please enter your email';
  static const String errorInvalidEmail = 'Please enter a valid email';
  static const String errorEmptyPassword = 'Please enter your password';
  static const String errorShortPassword = 'Password must be at least 8 characters';
  static const String errorEmptyName = 'Please enter your full name';
  static const String errorEmptyProjectName = 'Please enter a project name';
  static const String errorEmptyDescription = 'Please describe your diagram';
  static const String errorNetwork = 'No internet connection';
  static const String errorUnauthorized = 'Session expired. Please login again.';
  static const String errorServer = 'Server error. Please try again.';

  // ── Success ──────────────────────────────────────────────
  static const String successLogin = 'Welcome back!';
  static const String successRegister = 'Account created successfully!';
  static const String successProjectCreated = 'Project created!';
  static const String successLogout = 'Logged out successfully';
}
