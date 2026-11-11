#Region Internal

// Returns: 
//  String - Right to launch
Function RightToStart() Export
	
	Return NStr("vi = 'Khởi động';
				|ru = 'Запуск';
				|en = 'Start'; fa = 'شروع';
				|it = 'Avvio';
				|pl = 'Uruchomienie';
				|tr = 'Başlat'");
	
EndFunction

// Returns: 
//  String - The right start-up and administration
Function LaunchAndAdministrationRights() Export
	
	Return NStr("vi = 'Khởi động và quản trị';
				|ru = 'Запуск и администрирование';
				|en = 'Launch and administration'; fa = 'راه‌اندازی و مدیریت';
				|it = 'Avvio e amministrazione';
				|pl = 'Uruchomienie i administrowanie';
				|tr = 'Başlatma ve yönetim'");
	
EndFunction

// Returns: 
//  String - the owner role.
Function OwnerRole() Export
	
	Return NStr("vi = 'Đối tượng chủ';
				|ru = 'Владелец';
				|en = 'Owner'; fa = 'مالک';
				|it = 'Titolare';
				|pl = 'Owner';
				|tr = 'Sahip'");
	
EndFunction

// Returns: 
//  String - the administrator role.
Function RoleAdministrator() Export
	
	Return NStr("vi = 'Người quản trị';
				|ru = 'Администратор';
				|en = 'Administrator'; fa = 'مدیر سیستم';
				|it = 'Amministratore';
				|pl = 'Administrator';
				|tr = 'Yönetici'");
	
EndFunction

// Returns: 
//  String - the user role.
Function UserRole_() Export
	
	Return NStr("vi = 'Người sử dụng';
				|ru = 'Пользователь';
				|en = 'User'; fa = 'کاربر';
				|it = 'Utente';
				|pl = 'User';
				|tr = 'Kullanıcı'");
	
EndFunction

// Parameters: 
//  Id - String
// 
// Returns: 
//  String
Function RolePresentation(Id) Export
	
	If Id = "owner" Then
		Return OwnerRole();
	ElsIf Id = "administrator" Then
		Return RoleAdministrator();
	ElsIf Id = "user" Then  
		Return UserRole_();
	ElsIf Id = "operator" Then
		Return OperatorRole();
	EndIf;
	
EndFunction

// Parameters: 
//  Presentation - String
// 
// Returns: 
//  String - Role API ID
Function APIIDForRole(Presentation) Export
	
	If Presentation = OwnerRole() Then
		Return "owner";
	ElsIf Presentation = RoleAdministrator() Then
		Return "administrator";
	ElsIf Presentation = UserRole_() Then
		Return "user";
	ElsIf Presentation = OperatorRole() Then
		Return "operator";
	EndIf;
	
EndFunction

// Parameters: 
//  Presentation - String
// 
// Returns: 
//  String
Function APIID(Presentation) Export
	
	If Presentation = RightToStart() Then
		Return "user";
	ElsIf Presentation = LaunchAndAdministrationRights() Then
		Return "administrator";
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function OperatorRole()
	
	Return NStr("vi = 'Toán tử';
				|ru = 'Оператор';
				|en = 'Operator'; fa = 'Operator';
				|it = 'Operatore';
				|pl = 'Operator';
				|tr = 'Operatör'");
	
EndFunction

#EndRegion
