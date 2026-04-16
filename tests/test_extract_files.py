import sys
from unittest.mock import MagicMock
import importlib.util
import os

# Mock extract_utils modules before importing extract-files.py
mock_extract_utils = MagicMock()
sys.modules['extract_utils'] = mock_extract_utils
sys.modules['extract_utils.fixups_blob'] = MagicMock()
sys.modules['extract_utils.fixups_lib'] = MagicMock()
sys.modules['extract_utils.main'] = MagicMock()

# Path to extract-files.py
current_dir = os.path.dirname(os.path.abspath(__file__))
extract_files_path = os.path.join(os.path.dirname(current_dir), 'extract-files.py')

# Load extract-files.py
spec = importlib.util.spec_from_file_location("extract_files", extract_files_path)
extract_files = importlib.util.module_from_spec(spec)
spec.loader.exec_module(extract_files)

def test_lib_fixup_vendor_suffix_vendor():
    """Test that 'vendor' partition returns the suffixed library name."""
    assert extract_files.lib_fixup_vendor_suffix('libtest', 'vendor') == 'libtest_vendor'

def test_lib_fixup_vendor_suffix_system():
    """Test that 'system' partition returns None."""
    assert extract_files.lib_fixup_vendor_suffix('libtest', 'system') is None

def test_lib_fixup_vendor_suffix_product():
    """Test that 'product' partition returns None."""
    assert extract_files.lib_fixup_vendor_suffix('libtest', 'product') is None

def test_lib_fixup_vendor_suffix_empty_partition():
    """Test that empty partition returns None."""
    assert extract_files.lib_fixup_vendor_suffix('libtest', '') is None

def test_lib_fixup_vendor_suffix_with_extra_args():
    """Test that the function handles extra arguments correctly."""
    assert extract_files.lib_fixup_vendor_suffix('libtest', 'vendor', 'extra_arg', kwarg='extra_value') == 'libtest_vendor'
