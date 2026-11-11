#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	AttributesToUnlock = AttributesToUnlock();
	Close(AttributesToUnlock);

EndProcedure

&AtClient
Procedure CheckObjectUsage(Command)
	
	CheckAccountUsageOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationObjectUsedURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Report" Then
		OpenAccountAccount();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CheckAccountUsageOnServer()
	
	SetPrivilegedMode(True);
	
	Account = Parameters.Object;
	
	FullMetadataObjectName = "";
	
	
	If TypeOf(Account) = Type("ChartOfAccountsRef.International") Then
		AccountProperties = FinancialAccountingServerCached.AccountProperties(Account);   
		If AccountProperties.OptionForGeneratingTransactions = PredefinedValue("Enum.EntryGenerationOptions.WithCorrespondence") Then
			FullMetadataObjectName = "AccountingRegister.International.Turnovers(,,, Account = &Account,,,,)";
		ElsIf AccountProperties.OptionForGeneratingTransactions = PredefinedValue("Enum.EntryGenerationOptions.WithoutCorrespondence") Then 
			FullMetadataObjectName = "AccountingRegister.InternationalWithoutCorrespondence.Turnovers(,,, Account = &Account,,)";
		EndIf;
	EndIf;
	QueryTemplate =
		"SELECT DISTINCT
		|	AccountingRegisterTurnovers.Organization AS Organization
		|FROM
		|	&FullMetadataObjectName AS AccountingRegisterTurnovers";
	

	QueryText = StrReplace(QueryTemplate, "&FullMetadataObjectName", FullMetadataObjectName);
	
	Query = New Query;
    Query.Text = QueryText;
	Query.SetParameter("Account", Account);
	QueryResult = Query.Execute();
	
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		Items.ObjectIsUsedPagesGroup.CurrentPage = Items.ObjectIsUsedObjectIsNotUsedGroup;
		Items.EnableEdit.Enabled = True;
	Else

		Items.ObjectIsUsedPagesGroup.CurrentPage = Items.ObjectIsUsedObjectIsUsedGroup;

		If Users.IsFullUser() Then
			
			Items.DecorationObjectUsed.Title = StringFunctions.FormattedString(
				NStr("vi = 'Sử dụng tài khoản trong các bút toán.
					|Việc tắt dấu hiệu ghi nhận hoặc xóa dạng khoản mục có thể dẫn đến xóa dữ liệu.
					|Hãy mở báo cáo ""Bảng cân đối tài khoản theo tài khoản"" để xem bút toán';
					|ru = 'Счет используется в проводках.
					|Выключение признаков учета или удаление видов субконто может привести к удалению данных.
					|Откройте отчет ""Оборотно-сальдовую ведомость по счету"" для просмотра проводок';
					|en = 'The account is used in entries.
					|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
					|To view entries, open the ""Trial balance for account"" report'; fa = 'The account is used in entries.
					|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
					|To view entries, open the ""Trial balance for account"" report';
					|it = 'Счет используется в проводках.
					|Выключение признаков учета или удаление видов субконто может привести к удалению данных.
					|Откройте отчет ""Оборотно-сальдовую ведомость по счету"" для просмотра проводок';
					|pl = 'The account is used in entries.
					|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
					|To view entries, open the ""Trial balance for account"" report';
					|tr = 'Hesap, girişlerde kullanılmaktadır.
					|Muhasebe özelliklerinin devre dışı bırakılması veya ekstra boyut türlerinin silinmesi, verilerin silinmesine neden olabilir.
					|Girişleri görüntülemek için ""Hesaba göre mizan"" raporunu açın'"));

			Items.EnableEdit.Enabled = True;

		Else

			OrganizationsFromTransactions = QueryResult.Unload().UnloadColumn("Organization");

			Query = New Query;
			Query.Text =
			"SELECT DISTINCT ALLOWED
			|	Companies.Ref AS Organization
			|FROM
			|	Catalog.Companies AS Companies";

			AvailableCompanies = Query.Execute().Unload().UnloadColumn("Organization");

			ThereAreInaccessibleOrganizations = False;
			For Each OrganizationOfTransactions In OrganizationsFromTransactions Do
				If AvailableCompanies.Find(OrganizationOfTransactions) = Undefined Then
					ThereAreInaccessibleOrganizations = True;
					Break;
				EndIf;
			EndDo;
			
			If ThereAreInaccessibleOrganizations Then
				Items.DecorationObjectUsed.Title = StringFunctions.FormattedString(
					NStr("vi = 'Sử dụng tài khoản trong các bút toán.
						|Việc tắt dấu hiệu ghi nhận hoặc xóa dạng khoản mục có thể dẫn đến xóa dữ liệu.
						|Hãy mở báo cáo ""Bảng cân đối tài khoản theo tài khoản để xem bút toán.
						|Ngoài ra, không cho phép xem tài khoản mà được sử dụng trong các bút toán theo doanh nghiệp.';
						|ru = 'Счет используется в проводках.
						|Выключение признаков учета или удаление видов субконто может привести к удалению данных.
						|Откройте отчет ""Оборотно-сальдовую ведомость по счету"" для просмотра проводок.
						|Также счет используется в проводках по организациям недоступных для просмотра.';
						|en = 'The account is used in entries.
						|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
						|To view entries, open the ""Trial balance for account"" report.
						|The account is also used in entries of the companies that are not available for view.'; fa = 'The account is used in entries.
						|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
						|To view entries, open the ""Trial balance for account"" report.
						|The account is also used in entries of the companies that are not available for view.';
						|it = 'Счет используется в проводках.
						|Выключение признаков учета или удаление видов субконто может привести к удалению данных.
						|Откройте отчет ""Оборотно-сальдовую ведомость по счету"" для просмотра проводок.
						|Также счет используется в проводках по организациям недоступных для просмотра.';
						|pl = 'The account is used in entries.
						|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
						|To view entries, open the ""Trial balance for account"" report.
						|The account is also used in entries of the companies that are not available for view.';
						|tr = 'Hesap, girişlerde kullanılmaktadır.
						|Muhasebe özelliklerinin devre dışı bırakılması veya ekstra boyut türlerinin silinmesi, verilerin silinmesine neden olabilir.
						|Girişleri görüntülemek için ""Hesaba göre mizan"" raporunu açın.
						|Ayrıca hesap, görüntülenemeyen iş yerlerine yapılan girişlerde kullanılmaktadır.'"));
			Else
				Items.DecorationObjectUsed.Title = StringFunctions.FormattedString(
					NStr("vi = 'Sử dụng tài khoản trong các bút toán.
						|Việc tắt dấu hiệu ghi nhận hoặc xóa dạng khoản mục có thể dẫn đến xóa dữ liệu.
						|Hãy mở báo cáo ""Bảng cân đối tài khoản theo tài khoản"" để xem bút toán.';
						|ru = 'Счет используется в проводках.
						|Выключение признаков учета или удаление видов субконто может привести к удалению данных.
						|Откройте отчет ""Оборотно-сальдовую ведомость по счету"" для просмотра проводок.';
						|en = 'The account is used in entries.
						|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
						|To view entries, open the ""Trial balance for account"" report.'; fa = 'The account is used in entries.
						|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
						|To view entries, open the ""Trial balance for account"" report.';
						|it = 'Счет используется в проводках.
						|Выключение признаков учета или удаление видов субконто может привести к удалению данных.
						|Откройте отчет ""Оборотно-сальдовую ведомость по счету"" для просмотра проводок.';
						|pl = 'The account is used in entries.
						|If you disable accounting flags or delete extra dimension types, it might result in the data deletion.
						|To view entries, open the ""Trial balance for account"" report.';
						|tr = 'Hesap, girişlerde kullanılmaktadır.
						|Muhasebe özelliklerinin devre dışı bırakılması veya ekstra boyut türlerinin silinmesi, verilerin silinmesine neden olabilir.
						|Girişleri görüntülemek için ""Hesaba göre mizan"" raporunu açın.'"));				
			EndIf;
			
		EndIf;

	EndIf;
	
EndProcedure

&AtClient
Procedure OpenAccountAccount()

	Account = Parameters.Object;
	

	If TypeOf(Account) = Type("ChartOfAccountsRef.International") Then
		
		OpeningParameters = OSVParametersByAccountInternational(Account);
		ReportName = OpeningParameters.ReportName;
		FormParameters = OpeningParameters.FormParameters;	
		OpenForm("Report." + ReportName + ".Form", FormParameters,, True);
		
	EndIf;
EndProcedure
&AtServer
Function OSVParametersByAccountInternational(Account)
	
	AccountProperties = FinancialAccountingServerCached.AccountProperties(Account);
	
	If AccountProperties.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		ReportName = Metadata.Reports.AccountingReportFinancialAccounting.Name;
		ReportOptionName = "OSV_OnAccountOfInternational";
		
		SchemaName = Metadata.Reports.AccountingReportFinancialAccounting.MainDataCompositionSchema.Name;
		DataCompositionSchema = Reports.AccountingReportFinancialAccounting.GetTemplate(SchemaName); // DataCompositionSchema -
		OptionSettings = DataCompositionSchema.SettingVariants[ReportOptionName].Settings;
	Else
		ReportName = Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.Name;
		ReportOptionName = "OSVOnAccountWithCorrespondenceInternational";
		
		SchemaName = Metadata.Reports.AccountingReportWithCorrespondenceFinancialAccounting.MainDataCompositionSchema.Name;
		DataCompositionSchema = Reports.AccountingReportWithCorrespondenceFinancialAccounting.GetTemplate(SchemaName); // DataCompositionSchema -
		OptionSettings = DataCompositionSchema.SettingVariants[ReportOptionName].Settings;
	EndIf;

	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.LoadSettings(OptionSettings);
	Settings = SettingsComposer.Settings;
	SettingsFilter = Settings.Filter;
	
	// Let's set the parameters of the decryption report
	ReportPeriod = New Structure;
	ReportPeriod.Insert("StartDate", Date(1, 1, 1));
	ReportPeriod.Insert("EndDate", Date(1, 1, 1));
	DataCompositionClientServer.SetParameter(Settings, "ReportPeriod", ReportPeriod);
	DataCompositionClientServer.SetParameter(Settings, "PresentationOfInvoicesByCode", True);
	ItIsFunctionalCurrency = True;
	DataCompositionClientServer.SetParameter(Settings, "IndicatorAmount", ItIsFunctionalCurrency);
	DataCompositionClientServer.SetParameter(Settings, "IndicatorSumOfPresentation", Not ItIsFunctionalCurrency);
	
	FinancialReportingServer.SetFilter(SettingsFilter,"Account", Account);
	DataCompositionClientServer.SetParameter(Settings, "ChartOfAccounts", AccountProperties.ChartOfAccounts);
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", ReportOptionName); 
	FormParameters.Insert("UserSettings", SettingsComposer.UserSettings);
	FormParameters.Insert("GenerateOnOpen", True);

	OpeningParameters = New Structure;
	OpeningParameters.Insert("ReportName", ReportName);
	OpeningParameters.Insert("FormParameters", FormParameters);
	
	Return OpeningParameters;
	
EndFunction
&AtServer
Function AttributesToUnlock()
	
	AttributesToUnlock = New Array;
	Account = Parameters.Object;
	
	
	If TypeOf(Account) = Type("ChartOfAccountsRef.International") Then
    	AttributesToUnlock = ChartsOfAccounts.International.GetObjectAttributesToLock();
	EndIf;
	Return AttributesToUnlock;
	
EndFunction

#EndRegion
