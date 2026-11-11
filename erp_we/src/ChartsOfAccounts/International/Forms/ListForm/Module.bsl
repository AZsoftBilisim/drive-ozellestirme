
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	If Parameters.Filter.Property("ChartOfAccounts") And ValueIsFilled(Parameters.Filter.ChartOfAccounts) Then
		ChartOfAccounts = Parameters.Filter.ChartOfAccounts;
		Parameters.Filter.Delete("ChartOfAccounts");
		Items.ChartOfAccounts.Enabled = False;
	EndIf;
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	CommonClientServer.SetDynamicListParameter(List, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts);
	
	CommonClientServer.SetDynamicListParameter(List, "AssetBalanceSheetName", NStr("vi = 'Tài sản';
																					|ru = 'Актив';
																					|en = 'Asset'; fa = 'دارایی';
																					|it = 'Attivo';
																					|pl = 'Asset';
																					|tr = 'Varlık'"));
	CommonClientServer.SetDynamicListParameter(List, "Liabilities", NStr("vi = 'Nguồn vốn';
																		|ru = 'Пассив';
																		|en = 'Liability'; fa = 'بدهی';
																		|it = 'Passivo';
																		|pl = 'Liability';
																		|tr = 'Yükümlülük'"));
	CommonClientServer.SetDynamicListParameter(List, "AssetLiability", NStr("vi = 'Tài sản/Nguồn vốn';
																			|ru = 'Актив/Пассив';
																			|en = 'Asset/Liability'; fa = 'دارایی/بدهی';
																			|it = 'Attivo/passivo';
																			|pl = 'Aktywa/Pasywa';
																			|tr = 'Varlık/Yükümlülük'"));
	CommonClientServer.SetDynamicListParameter(List, "TurnoversOnly", " ("+NStr("vi = 'ps';
																				|ru = 'об';
																				|en = 'turn'; fa = 'turn';
																				|it = 'am';
																				|pl = 'turn';
																				|tr = 'hakkında'")+")");
	
	Items.AccountingByLinesOfBusiness.Visible = Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed();
	
	YouCanChangeChartOfAccounts = AccessRight("Update", Metadata.ChartsOfAccounts.International);
	Items.Load.Visible = YouCanChangeChartOfAccounts;
	Items.Unload.Visible = YouCanChangeChartOfAccounts;
	CurrentLanguageSuffix = NationalLanguageSupportServer.CurrentLanguageSuffix(); 
	
	ExtDimensionNameInCurrentLanguage = "InternationalExtdimensionDay.ExtDimensionType.Description" + CurrentLanguageSuffix;
	ExpressionNameOfExtDimension =
	"CASE 
	|	WHEN &ExtDimensionNameInCurrentLanguage <> """"
	|		THEN &ExtDimensionNameInCurrentLanguage
	|	ELSE InternationalExtdimensionDay.ExtDimensionType.Description
	|END"; 
	ExpressionNameOfExtDimension = StrReplace(ExpressionNameOfExtDimension, "&ExtDimensionNameInCurrentLanguage", ExtDimensionNameInCurrentLanguage);	
	List.QueryText = StrReplace(List.QueryText, "InternationalExtdimensionDay.ExtDimensionType.Description", ExpressionNameOfExtDimension); 
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	CommonClientServer.SetDynamicListParameter(List, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	CommonClientServer.SetDynamicListParameter(List, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Not CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

&AtClient
Procedure SettingUpTheFormationOfTransactionsForAccountingObjects(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("ChartOfAccounts", ChartOfAccounts);
	
	OpenForm("DataProcessor.SettingUpFinancialAccountingAccounts.Form", FormParameters, ,  ThisObject);
	
EndProcedure

&AtClient
Procedure SettingUpTheGenerationOfTransactionsForBusinessTransactions(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("ChartOfAccounts", ChartOfAccounts);
	
	OpenForm("DataProcessor.PostingTemplatesSetupForFinancialAccounting.Form.PostingTemplatesSetup", FormParameters, ,  ThisObject);
	
EndProcedure


&AtClient
Procedure Load(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("ChartOfAccounts", ChartOfAccounts);
	
	OpenForm("DataProcessor.ChartOfAccountsExportImportWizard.Form.Load", FormParameters, ,  ThisObject);
	
EndProcedure

&AtClient
Procedure Unload(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("ChartOfAccounts", ChartOfAccounts);
	
	OpenForm("DataProcessor.ChartOfAccountsExportImportWizard.Form.Upload0", FormParameters, ,  ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion