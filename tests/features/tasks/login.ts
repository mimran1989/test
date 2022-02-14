import { AuthenticatedUser } from '../abilities/authenticate';
import { Actor } from '../support/actor';
import Browse from './interactions/browse';
import Click from './interactions/click';
import Enter from './interactions/enter';
import LoginPage from './view-models/loginPage';

const Login = {
	withCredentials: async(actor: Actor) => {
		const authUserInfo: AuthenticatedUser = actor.recall(AuthenticatedUser.type);
		let loginResults;
		if (!authUserInfo.isLoggedIn) {
			const { loginUrl, username, password } = authUserInfo;
			loginResults = await actor.attemptsTo(
				Browse.to.theUrl(loginUrl),
				Enter.theValue(username)
					.into(LoginPage.usernameInput),
				Enter.theValue(password).into(LoginPage.passwordInput),
				Click.on(LoginPage.logInButton),
				async() => authUserInfo.loggedIn(),
			);
		}

		return loginResults;
	},
};

export default Login;
