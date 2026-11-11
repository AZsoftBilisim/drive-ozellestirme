#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SettingsForOpeningForms.User,
	|	SettingsForOpeningForms.OpenedForm
	|INTO SettingsForOpeningForms
	|FROM
	|	&SettingsForOpeningForms AS SettingsForOpeningForms
	|WHERE
	|	SettingsForOpeningForms.OpenByDefault
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT NestedQuery.OpenedForm) AS NumberOfForms,
	|	NestedQuery.User AS User
	|FROM
	|	(SELECT
	|		SettingsForOpeningForms.User AS User,
	|		SettingsForOpeningForms.OpenedForm AS OpenedForm
	|	FROM
	|		SettingsForOpeningForms AS SettingsForOpeningForms
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ConfigureFormOpeningOnStartingApplication.User,
	|		ConfigureFormOpeningOnStartingApplication.OpenedForm
	|	FROM
	|		InformationRegister.ConfigureFormOpeningOnStartingApplication AS ConfigureFormOpeningOnStartingApplication
	|	WHERE
	|		ConfigureFormOpeningOnStartingApplication.OpenByDefault) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.User
	|
	|HAVING
	|	COUNT(DISTINCT NestedQuery.OpenedForm) > 1";
	
	Query.SetParameter("SettingsForOpeningForms", ThisObject.Unload());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Người sử dụng ""%User%"" được chỉ định hơn một biểu mẫu mở ra mặc định.';
							|ru = 'Пользователю ""%User%"" назначено более одной формы, открываемой по умолчанию.';
							|en = 'More than one form opened by default is assigned to the ""%User%"" user.'; fa = 'More than one form opened by default is assigned to the ""%User%"" user.';
							|it = 'All''utente ""%User%"" è stato assegnato più di un modulo predefinito.';
							|pl = 'Użytkownik ""%User%"" ma przypisany więcej niż jeden domyślny formularz, który otwiera się domyślnie.';
							|tr = '""%User%"" kullanıcısına birden fazla varsayılan form atanmıştır.'");
		
		MessageText = StrReplace(MessageText, "%User%", Selection.User); 
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
