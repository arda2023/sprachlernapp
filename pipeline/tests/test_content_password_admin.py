import importlib.util
from pathlib import Path
from unittest.mock import Mock

import pytest

spec=importlib.util.spec_from_file_location('password_admin',Path(__file__).parents[1]/'scripts/set_content_user_password.py')
admin=importlib.util.module_from_spec(spec);spec.loader.exec_module(admin)


def existing():
    return {'id':admin.USER_ID,'email':'existing@example.test',
            'email_confirmed_at':'2026-10-16T00:00:00Z','banned_until':None}


def test_interactive_admin_updates_only_fixed_existing_uid(monkeypatch,capsys):
    monkeypatch.setattr(admin.sys,'argv',['script'])
    monkeypatch.setattr(admin.sys.stdin,'isatty',lambda:True)
    inputs=iter([admin.PROJECT_REF,'existing@example.test',admin.USER_ID])
    secrets=iter(['synthetic-admin-key','synthetic-password','synthetic-password'])
    monkeypatch.setattr('builtins.input',lambda prompt:next(inputs))
    monkeypatch.setattr(admin.getpass,'getpass',lambda prompt:next(secrets))
    request=Mock(return_value=existing());monkeypatch.setattr(admin,'admin_request',request)
    admin.main()
    assert admin.PROJECT_URL=='https://yevntxclpchapacqdizm.supabase.co'
    assert request.call_args_list[0].args==('GET','synthetic-admin-key')
    assert request.call_args_list[1].args==('PUT','synthetic-admin-key',{'password':'synthetic-password'})
    output=capsys.readouterr()
    assert 'synthetic' not in output.out+output.err


def test_wrong_project_stops_before_secret_or_network(monkeypatch):
    monkeypatch.setattr(admin.sys,'argv',['script']);monkeypatch.setattr(admin.sys.stdin,'isatty',lambda:True)
    monkeypatch.setattr('builtins.input',lambda prompt:'wrong-project')
    secret=Mock();request=Mock()
    monkeypatch.setattr(admin.getpass,'getpass',secret);monkeypatch.setattr(admin,'admin_request',request)
    with pytest.raises(admin.AdminSetupError):admin.main()
    secret.assert_not_called();request.assert_not_called()


@pytest.mark.parametrize('change',[
    {'id':'different-uid'},{'email':'different@example.test'},
    {'email_confirmed_at':None},{'banned_until':'2999-01-01T00:00:00Z'},
])
def test_user_mismatch_unconfirmed_or_banned_aborts(change):
    with pytest.raises(admin.AdminSetupError):admin.validate_user({**existing(),**change},'existing@example.test')
