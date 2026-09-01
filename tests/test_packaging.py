import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "tools" / "package-janus-plus-rc.ps1").read_text(encoding="utf-8")
NOTES = (ROOT / "RELEASE-NOTES-4.0-RC2.md").read_text(encoding="utf-8")
LEGAL = (ROOT / "LEGAL-NOTICES.md").read_text(encoding="utf-8")


class JanusPlusPackagingTests(unittest.TestCase):
    def test_rc_package_has_stable_release_identity(self):
        self.assertIn('Version = "4.0.0-rc.2"', SCRIPT)
        self.assertIn('"JANUS-Plus-$Version"', SCRIPT)
        self.assertIn("JANUS+ 4.00 RC 2", NOTES)
        self.assertIn("1 de septiembre de 2026", NOTES)

    def test_package_contains_binary_docs_notes_and_hash(self):
        self.assertIn("build-native.ps1", SCRIPT)
        self.assertIn('"README.md"', SCRIPT)
        self.assertIn('"RELEASE-NOTES-4.0-RC2.md"', SCRIPT)
        self.assertIn('"LEGAL-NOTICES.md"', SCRIPT)
        self.assertIn('"SHA256SUMS.txt"', SCRIPT)
        self.assertIn('"$baseName-SHA256.txt"', SCRIPT)
        self.assertIn("Get-FileHash", SCRIPT)
        self.assertIn("Compress-Archive", SCRIPT)

    def test_external_themes_are_not_bundled(self):
        self.assertNotIn("assets\\windows-themes", SCRIPT)
        self.assertNotIn("assets\\theme-packs", SCRIPT)
        self.assertIn("se publican como archivos separados", NOTES)

    def test_public_release_excludes_microsoft_audio(self):
        self.assertIn("sonidos originales de JANUS", NOTES)
        self.assertIn("No incluye ni redistribuye sonidos extraídos de Microsoft Windows", NOTES)
        self.assertIn("no redistribuyen archivos de audio pertenecientes a Microsoft Windows", LEGAL)


if __name__ == "__main__":
    unittest.main()
