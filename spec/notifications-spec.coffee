describe "Notifications", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('notifications')

    waitsForPromise ->
      activationPromise

  describe "when the package is activated", ->
    it "attaches an atom-notifications element to the dom", ->
      expect(workspaceElement.querySelector('atom-notifications')).toBeDefined()
