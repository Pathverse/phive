import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest


spec = importlib.util.spec_from_file_location(
    'proof_steps', Path(__file__).resolve().parents[1] / 'steps' / 'proof_steps.py'
)
binding = importlib.util.module_from_spec(spec)
spec.loader.exec_module(binding)


class ProofBindingTest(unittest.TestCase):
    def test_rejects_unknown_proof_before_launch(self):
        context = SimpleNamespace(scenario=SimpleNamespace(tags=['proof_unknown']))
        with self.assertRaisesRegex(AssertionError, 'Unknown proof'):
            binding.step_bound(context)

    def test_requires_exactly_one_proof(self):
        for tags in [[], ['proof_router_crud', 'proof_hook_metadata']]:
            with self.subTest(tags=tags):
                context = SimpleNamespace(scenario=SimpleNamespace(tags=tags))
                with self.assertRaises(AssertionError):
                    binding.step_bound(context)


if __name__ == '__main__':
    unittest.main()
