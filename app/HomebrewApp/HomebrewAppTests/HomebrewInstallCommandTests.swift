import Testing
@testable import HomebrewApp

struct HomebrewInstallCommandTests {
    @Test func buildsTypeQualifiedInstallArguments() {
        let formula = HomebrewInstallCommand(packageName: "wget", kind: .formula)
        let cask = HomebrewInstallCommand(
            packageName: "darrylmorley/whatcable/whatcable",
            kind: .cask
        )

        #expect(formula.arguments == ["install", "--formula", "wget"])
        #expect(
            cask.arguments == [
                "install",
                "--cask",
                "darrylmorley/whatcable/whatcable"
            ]
        )
        #expect(cask.displayString == "brew install --cask darrylmorley/whatcable/whatcable")
    }
}
