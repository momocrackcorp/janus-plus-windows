import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN_SOURCE = (ROOT / "src" / "MigradorSeguro.cs").read_text(encoding="utf-8")
THEME_SOURCE = (ROOT / "src" / "DualityThemeForm.cs").read_text(encoding="utf-8")
SOURCE = MAIN_SOURCE + "\n" + THEME_SOURCE
BUILD = (ROOT / "build-native.ps1").read_text(encoding="utf-8")


class ThemeCatalogTests(unittest.TestCase):
    def test_external_themes_are_listed(self):
        for name, package in (
            ("Crux", "Crux"),
            ("Newaita", "Newaita"),
            ("Papirus", "Papirus"),
            ("WhiteSur", "WhiteSur"),
            ("La Capitaine", "La-Capitaine"),
            ("Retro", "Retro"),
            ("Silicon", "Silicon"),
        ):
            self.assertIn(f'Name="{name}"', SOURCE)
            self.assertIn(f"Tema-Iconos-{package}.zip", SOURCE)

    def test_all_theme_downloads_use_the_dedicated_release(self):
        self.assertEqual(THEME_SOURCE.count("releases/download/v4.0.0-rc.1/"), 9)
        self.assertNotIn("releases/download/v2.3.0-rc.2/", SOURCE)
        self.assertIn("momocrackcorp/janus-plus-windows", SOURCE)
        self.assertNotIn("momocrackcorp/janus-windows", SOURCE)

    def test_theme_packages_are_not_embedded(self):
        self.assertNotIn("janus-icons", BUILD.lower())
        self.assertNotIn("tema-iconos-", BUILD.lower())
        self.assertNotIn("janus-duality-v1.zip", BUILD.lower())
        self.assertNotIn("janus-duality-iconos-v1.zip", BUILD.lower())

    def test_each_theme_has_its_own_storage(self):
        self.assertIn('"IconPacks",SelectedTheme.Id', SOURCE)
        self.assertIn('"IconThemes",SelectedTheme.Id', SOURCE)

    def test_folder_icon_changes_refresh_quick_access(self):
        self.assertIn("ApplyFolderIcon(folder.Item2,folder.Item3,folder.Item4)", SOURCE)
        self.assertIn("foreach(string shellId in shellIds)SetIconValue", SOURCE)
        self.assertIn("NotifyFolder(path)", SOURCE)
        self.assertIn('ie4uinit.exe","-ClearIconCache', SOURCE)
        self.assertIn('ie4uinit.exe","-show', SOURCE)
        self.assertIn('Process.GetProcessesByName("explorer")', SOURCE)
        self.assertIn('EntryPoint="SHChangeNotify"', SOURCE)

    def test_quick_access_icons_are_backed_up_and_reversible(self):
        self.assertIn("foreach(string shellId in folder.Item4)", SOURCE)
        self.assertIn("foreach(string path in IconKeyPaths(shellId))AddCapture", SOURCE)
        self.assertIn("MergeOriginalBackup(state)", SOURCE)
        self.assertIn("RestoreState(state)", SOURCE)
        for clsid in (
            "A8CDFF1C-4878-43BE-B5FD-F8091C1C60D0",
            "374DE290-123F-4565-9164-39C4925E467B",
            "B4BFCC3A-DB2C-424C-B029-7FE99A87C641",
            "3ADD1653-EB32-4CB0-BBD7-DFA0ABB5ACCA",
            "1CF1260C-4DD0-4EBB-811F-33C572699FDE",
            "A0953C92-50DC-43BF-BE83-3742FED03C9C",
        ):
            self.assertIn(clsid, SOURCE)


if __name__ == "__main__":
    unittest.main()
