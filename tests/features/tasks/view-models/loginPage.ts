import { Select } from '../../support/componentSelector';

const loginPage = {
	usernameInput: Select('input').withAttribute('id', 'username'),
	passwordInput: Select('input').withAttribute('id', 'password'),
	logInButton: Select('input').withAttribute('id', 'Login'),
};

export default loginPage;
