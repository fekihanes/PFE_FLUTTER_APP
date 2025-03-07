import 'package:flutter/material.dart';
import 'package:flutter_application/custom_widgets/CustomTextField.dart';
import 'package:flutter_application/services/auth_service.dart';
import 'package:flutter_application/view/admin/home_page_admin.dart';
import 'package:flutter_application/view/manager/home_page_manager.dart';
import 'package:flutter_application/view/user/home_page_user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isConnexionSelected = true;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmationVisible = false;
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_isConnexionSelected) {
        result = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          context
        );
      } else {
        result = await _authService.register(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _passwordConfirmationController.text.trim(),
          context
        );
      }

      if (result['success'] && mounted) {
        if (_isConnexionSelected) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('role')??'' ;
    if(role=='admin'){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageAdmin()));
    }else if(role=='manager'){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageManager()));
    }else if(role=='user'){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageUser()));
    }else{
          _showSuccessSnackbar("bar nyyyk omk");
    }
        } else {
          _showSuccessSnackbar(AppLocalizations.of(context)!.unverified_email);
        }
      } else if (mounted) {
        _showErrorSnackbar(result['error']);
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    if (await _authService.isAuthenticated()) {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role') ?? '';

      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          switch (role) {
            case 'admin':
              return const HomePageAdmin();
            case 'manager':
              return const HomePageManager();
            case 'user':
              return const HomePageUser();
            default:
              return const LoginPage();
          }
        },
      ));
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    print(email);
    if (email.isEmpty) {
      _showErrorSnackbar(AppLocalizations.of(context)!.emailRequired);
      return;
    }else{

    setState(() => _isLoading = true);

    try {
          
      final result = await _authService.forgotPassword(email, context);
      if (result['success']) {
        _showSuccessSnackbar(AppLocalizations.of(context)!.email_sender);
      } else {
        _showErrorSnackbar(result['error']);
      }
    } catch (e) {
      _showErrorSnackbar(AppLocalizations.of(context)!.errorSendingLink+ e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImage(),
              const SizedBox(height: 20),
              _buildToggleButtons(localization),
              const SizedBox(height: 20),
              if (!_isConnexionSelected) ...[
                _buildNameField(localization),
                const SizedBox(height: 10),
                _buildPhoneField(localization),
                const SizedBox(height: 10),
              ],
              _buildEmailField(localization),
              const SizedBox(height: 10),
              _buildPasswordField(localization),
              if (!_isConnexionSelected) const SizedBox(height: 10),
              if (!_isConnexionSelected)
                _buildPasswordConfirmationField(localization),
              const SizedBox(height: 10),
              if (_isConnexionSelected) _buildForgotPassword(localization),
              const SizedBox(height: 30),
              _buildSubmitButton(localization),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.asset(
      'images/login_image.png',
      width: MediaQuery.of(context).size.width * 0.8,
    );
  }

  Widget _buildToggleButtons(AppLocalizations localization) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton(
          text: localization.connexion,
          isSelected: _isConnexionSelected,
          onTap: () => setState(() => _isConnexionSelected = true),
        ),
        _buildToggleButton(
          text: localization.inscription,
          isSelected: !_isConnexionSelected,
          onTap: () => setState(() => _isConnexionSelected = false),
        ),
      ],
    );
  }

  Widget _buildForgotPassword(AppLocalizations localization) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _forgotPassword,
        child: Text(
          localization.forgotPassword,
          style: const TextStyle(
            color: Color(0xFFFB8C00),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(AppLocalizations localization) {
    return CustomTextField(
      controller: _nameController,
      hintText: localization.name,
      icon: Icons.person,
      validator: (value) => value?.isEmpty ?? true
          ? '${localization.name} ${localization.isRequired}'
          : null,
    );
  }

  Widget _buildEmailField(AppLocalizations localization) {
    return CustomTextField(
      controller: _emailController,
      hintText: localization.email,
      icon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return localization.emailRequired;
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return localization.invalidEmail;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(AppLocalizations localization) {
    return CustomTextField(
      controller: _passwordController,
      hintText: localization.password,
      icon: Icons.lock,
      obscureText: !_isPasswordVisible,
      suffixIcon: IconButton(
        icon:
            Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
        onPressed: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return localization.passwordRequired;
        if (value.length < 6) return localization.passwordTooShort;
        return null;
      },
    );
  }

  Widget _buildPasswordConfirmationField(AppLocalizations localization) {
    return CustomTextField(
      controller: _passwordConfirmationController,
      hintText: localization.passwordConfirmation,
      icon: Icons.lock,
      obscureText: !_isPasswordConfirmationVisible,
      suffixIcon: IconButton(
        icon: Icon(_isPasswordConfirmationVisible
            ? Icons.visibility
            : Icons.visibility_off),
        onPressed: () => setState(
          () =>
              _isPasswordConfirmationVisible = !_isPasswordConfirmationVisible,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return localization.confirmPasswordRequired;
        if (value != _passwordController.text)
          return localization.passwordsDontMatch;
        return null;
      },
    );
  }

  Widget _buildPhoneField(AppLocalizations localization) {
    return CustomTextField(
      controller: _phoneController,
      hintText: localization.phone,
      icon: Icons.phone,
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return localization.phoneRequired;
        }
        if (value.length != 8) {
          return localization.phoneLengthError;
        }
        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
          return localization.phoneInvalid;
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(AppLocalizations localization) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleAuth,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFB8C00),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              _isConnexionSelected
                  ? localization.connexion
                  : localization.inscription,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFB8C00) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


}
