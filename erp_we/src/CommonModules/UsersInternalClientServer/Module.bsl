///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns the string of the day, days kind.
//
// Parameters:
//   Number                       - Number  - an integer to which to add numeration item.
//   FormatString             - String - see the parameter of the same name of the NumberInWords method,
//                                          for example, DE=True.
//   NumerationItemOptions - String - see the parameter of the same name of the NumberInWords method,
//                                          for example, NStr("en= day, day, days,,,,,,0'").
//
//  Returns:
//   String
//
Function IntegerSubject(Number, FormatString, NumerationItemOptions) Export
	
	Integer1 = Int(Number);
	
	NumberInWords = NumberInWords(Integer1, FormatString, NStr("vi = ',,,,,,,,0';
																|ru = ',,,,,,,,0';
																|en = ',,,,,,,,0'; fa = ',,,,,,,,0';
																|it = ',,,,,,,,0';
																|pl = ',,,,,,,,0';
																|tr = ',,,,,,,,0'"));
	
	SubjectAndNumberInWords = NumberInWords(Integer1, FormatString, NumerationItemOptions);
	
	Return StrReplace(SubjectAndNumberInWords, NumberInWords, "");
	
EndFunction

// Returns a structure that contains the names of security warning types.
// Each property contains the name of a key.
//
// Returns:
//  Structure:
//   * AfterUpdate - String
//   * BeforeAddExternalReportOrDataProcessor - String
//   * BeforeAddExtensions - String
//   * BeforeSelectUpdateFile - String
//   * BeforeSelectRole - String
//   * OnChangeDeniedExtensionsList - String
//   * BeforeOpenFile - String
//   * BeforeAddAddIn - String
//   * BeforeDeleteExtensionWithoutData - String
//   * BeforeDeleteExtensionWithData - String
//   * BeforeDisableExtensionWithData - String
//
Function SecurityWarningKinds() Export
	
	Result = New Structure;
	Result.Insert("AfterUpdate");
	Result.Insert("AfterObtainRight");
	Result.Insert("BeforeAddExternalReportOrDataProcessor");
	Result.Insert("BeforeEnableScheduledJobOfAdditionalDataProcessor");
	Result.Insert("BeforeAddExtensions");
	Result.Insert("BeforeSelectUpdateFile");
	Result.Insert("BeforeSelectRole");
	Result.Insert("OnChangeDeniedExtensionsList");
	Result.Insert("BeforeOpenFile");
	Result.Insert("BeforeAddAddIn");
	Result.Insert("BeforeDeleteExtensionWithoutData");
	Result.Insert("BeforeDeleteExtensionWithData");
	Result.Insert("BeforeDisableExtensionWithData");
	
	For Each KeyAndValue In Result Do
		Result[KeyAndValue.Key] = KeyAndValue.Key;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Generates the user name based on the  full name.
Function GetIBUserShortName(Val FullName) Export
	
	Separators = New Array;
	Separators.Add(" ");
	Separators.Add(".");
	
	ShortName = "";
	For Counter = 1 To 3 Do
		
		If Counter <> 1 Then
			ShortName = ShortName + Upper(Left(FullName, 1));
		EndIf;
		
		SeparatorPosition = 0;
		For Each Separator In Separators Do
			CurrentSeparatorPosition = StrFind(FullName, Separator);
			If CurrentSeparatorPosition > 0
			   And (    SeparatorPosition = 0
			      Or SeparatorPosition > CurrentSeparatorPosition ) Then
				SeparatorPosition = CurrentSeparatorPosition;
			EndIf;
		EndDo;
		
		If SeparatorPosition = 0 Then
			If Counter = 1 Then
				ShortName = FullName;
			EndIf;
			Break;
		EndIf;
		
		If Counter = 1 Then
			ShortName = Left(FullName, SeparatorPosition - 1);
		EndIf;
		
		FullName = Right(FullName, StrLen(FullName) - SeparatorPosition);
		While Separators.Find(Left(FullName, 1)) <> Undefined Do
			FullName = Mid(FullName, 2);
		EndDo;
	EndDo;
	
	Return ShortName;
	
EndFunction

// For the Users and ExternalUsers catalogs item form.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects:
//    * Items - FormAllItems:
//        ** CanSignIn - FormField
//                                  - FormFieldExtensionForACheckBoxField
//        ** ChangeAuthorizationRestriction - FormField
//                                               - FormFieldExtensionForACheckBoxField
//
Procedure UpdateLifetimeRestriction(Form) Export
	
	Items = Form.Items;
	
	Items.ChangeAuthorizationRestriction.Visible =
		Items.IBUserProperies.Visible And Form.AccessLevel.ListManagement;
	
	If Not Items.IBUserProperies.Visible Then
		Items.CanSignIn.Title = "";
		Return;
	EndIf;
	
	Items.ChangeAuthorizationRestriction.Enabled = Form.AccessLevel.AuthorizationSettings2;
	
	TitleWithRestriction = "";
	
	If Form.UnlimitedValidityPeriod Then
		TitleWithRestriction = NStr("vi = 'Cho phép đăng nhập vào ứng dụng (không hạn chế thời hạn)';
									|ru = 'Вход в приложение разрешен (без ограничения срока)';
									|en = 'Login allowed (no time limit)'; fa = 'Login allowed (no time limit)';
									|it = 'Вход в приложение разрешен (без ограничения срока)';
									|pl = 'Login allowed (no time limit)';
									|tr = 'Uygulamaya giriş yapılmasına izin verildi (süre kısıtlaması olmadan)'");
		
	ElsIf ValueIsFilled(Form.ValidityPeriod) Then
		TitleWithRestriction = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Cho phép đăng nhập vào ứng dụng (đến %1)';
																							|ru = 'Вход в приложение разрешен (до %1)';
																							|en = 'Login allowed (till %1)'; fa = 'Login allowed (till %1)';
																							|it = 'Вход в приложение разрешен (до %1)';
																							|pl = 'Login allowed (till %1)';
																							|tr = 'Uygulamaya girişe izin verildi (%1 kadar)'"),
			Format(Form.ValidityPeriod, "DLF=D"));
			
	ElsIf ValueIsFilled(Form.InactivityPeriodBeforeDenyingAuthorization) Then
		TitleWithRestriction = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Cho phép đăng nhập vào ứng dụng (cấm, nếu không làm việc quá %1)';
				|ru = 'Вход в приложение разрешен (запретить, если не работает более %1)';
				|en = 'Login allowed (revoke access after inactivity of %1)'; fa = 'Login allowed (revoke access after inactivity of %1)';
				|it = 'Вход в приложение разрешен (запретить, если не работает более %1)';
				|pl = 'Login allowed (revoke access after inactivity of %1)';
				|tr = 'Uygulamaya girişe izin verildi (%1''den fazla çalışmaması durumunda yasakla)'"),
			Format(Form.InactivityPeriodBeforeDenyingAuthorization, "NG=") + " "
				+ IntegerSubject(Form.InactivityPeriodBeforeDenyingAuthorization,
					"", NStr("vi = 'ngày,ngày,ngày,,,,,,0';
							|ru = 'день,дня,дней,,,,,,0';
							|en = 'day,days,,,0'; fa = 'day,days,,,0';
							|it = 'giorno, del giorno dei giorni,,,,,,0';
							|pl = 'dzień,dni,dni,,,,,,0';
							|tr = 'gün, gün, gün,,,,,,0'")));
	EndIf;
	
	If ValueIsFilled(TitleWithRestriction) Then
		Items.CanSignIn.Title = TitleWithRestriction;
		Items.ChangeAuthorizationRestriction.Title = NStr("vi = 'Thay đổi hạn chế';
															|ru = 'Изменить ограничение';
															|en = 'Change time restriction'; fa = 'تغییر محدودیت زمانی';
															|it = 'Modificare il limite';
															|pl = 'Zmień ograniczenie';
															|tr = 'Kısıtlamayı değiştir'");
	Else
		Items.CanSignIn.Title = "";
		Items.ChangeAuthorizationRestriction.Title = NStr("vi = 'Thiết lập hạn chế';
															|ru = 'Установить ограничение';
															|en = 'Set up time restriction'; fa = 'Set up time restriction';
															|it = 'Impostare un limite';
															|pl = 'Ustaw ograniczenie';
															|tr = 'Kısıtla'");
	EndIf;
	
EndProcedure

// For the Users and ExternalUsers catalogs item form.
//
// Parameters:
//  Form - See Catalog.Users.Form.ItemForm
//        - See Catalog.ExternalUsers.Form.ItemForm
//  PasswordIsSet - Boolean
//  AuthorizedUser - CatalogRef.Users
//                             - CatalogRef.ExternalUsers
//
Procedure CheckPasswordSet(Form, PasswordIsSet, AuthorizedUser) Export
	
	Items = Form.Items;
	
	If PasswordIsSet Then
		Items.PasswordExistsLabel.Title = NStr("vi = 'Đã đặt mật khẩu';
												|ru = 'Пароль установлен';
												|en = 'The password is set.'; fa = 'The password is set.';
												|it = 'Password impostata';
												|pl = 'Hasło ustawione';
												|tr = 'Şifre belirlendi'");
		Items.UserMustChangePasswordOnAuthorization.Title =
			NStr("vi = 'Yêu cầu đổi mật khẩu khi đăng nhập';
				|ru = 'Потребовать смену пароля при входе';
				|en = 'User must change password on next login'; fa = 'User must change password on next login';
				|it = 'Chiedere cambio della password all''accesso';
				|pl = 'Wymagaj zmiany hasła po zalogowaniu';
				|tr = 'Oturum açma sırasında şifre değişikliği talep et'");
	Else
		Items.PasswordExistsLabel.Title = NStr("vi = 'Mật khẩu trống';
												|ru = 'Пустой пароль';
												|en = 'Blank password'; fa = 'رمز عبور خالی';
												|it = 'Password vuota';
												|pl = 'Puste hasło';
												|tr = 'Boş şifre'");
		Items.UserMustChangePasswordOnAuthorization.Title =
			NStr("vi = 'Yêu cầu đặt mật khẩu khi đăng nhập';
				|ru = 'Потребовать установку пароля при входе';
				|en = 'User must set password on next login'; fa = 'User must set password on next login';
				|it = 'Richiedere la modifica della password all''accesso';
				|pl = 'Wymagaj ustawianie hasła podczas logowania';
				|tr = 'Oturum açma sırasında şifre belirlenmesini talep et'");
	EndIf;
	
	If PasswordIsSet
	   And Form.Object.Ref = AuthorizedUser Then
		
		Items.ChangePassword.Title = NStr("vi = 'Thay đổi mật khẩu...';
											|ru = 'Сменить пароль...';
											|en = 'Change password…'; fa = 'تغییر رمز عبور…';
											|it = 'Cambiare la password...';
											|pl = 'Zmień hasło...';
											|tr = 'Şifre değiştir...'");
	Else
		Items.ChangePassword.Title = NStr("vi = 'Đặt mật khẩu...';
											|ru = 'Установить пароль...';
											|en = 'Set password…'; fa = 'تعیین رمز عبور…';
											|it = 'Impostare la password...';
											|pl = 'Ustaw hasło...';
											|tr = 'Şifre belirle...'");
	EndIf;
	
EndProcedure

// For internal use only.
Function CurrentUser(AuthorizedUser) Export
	
	If TypeOf(AuthorizedUser) <> Type("CatalogRef.Users") Then
		ErrorText = NStr("vi = 'Không thể nhận được người sử dụng hiện tại
									|trong phiên làm việc của người sử dụng ngoài.';
									|ru = 'Невозможно получить текущего пользователя
									|в сеансе внешнего пользователя.';
									|en = 'Cannot get the current external user
									|in the external user session.'; fa = 'Cannot get the current external user
									|in the external user session.';
									|it = 'Impossibile recuperare l''utente corrente
									|nella sessione dell''utente esterno.';
									|pl = 'Nie można uzyskać bieżącego użytkownika
									|w sesji użytkownika zewnętrznego.';
									|tr = 'Geçerli kullanıcı
									| harici kullanıcı oturumunda alınamaz.'");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Return AuthorizedUser;
	
EndFunction

// For internal use only.
Function CurrentExternalUser(AuthorizedUser) Export
	
	If TypeOf(AuthorizedUser) <> Type("CatalogRef.ExternalUsers") Then
		ErrorText = NStr("vi = 'Không thể nhận được người sử dụng ngoài hiện tại
									|trong phiên làm việc của người sử dụng.';
									|ru = 'Невозможно получить текущего внешнего пользователя
									|в сеансе пользователя.';
									|en = 'Cannot get the current external user
									|in the user session.'; fa = 'Cannot get the current external user
									|in the user session.';
									|it = 'Impossibile recuperare l''utente esterno corrente
									|nella sessione dell''utente.';
									|pl = 'Nie można uzyskać bieżącego użytkownika zewnętrznego 
									|w sesji użytkownika.';
									|tr = 'Geçerli harici kullanıcı, 
									| kullanıcı oturumunda alınamıyor.'");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Return AuthorizedUser;
	
EndFunction

#EndRegion
