
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("UseStatusFilter") Then
		UseStatusFilter = Parameters.UseStatusFilter;
	ElsIf Parameters.Property("BudgetingModel") Then
		UseStatusFilter = Common.ObjectAttributeValue(Parameters.BudgetingModel,
			"UseBudgetConfirmation");
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	MainStorageID = Parameters.MainStorageID;
	LocationOptionOfActualDataOffset = Parameters.LocationOptionOfActualDataOffset;
	
	If Parameters.Property("ArbitraryIndicator") Then
		Items.NegativeValue.Visible = False;
	EndIf;
	
	Title = "";
	If Not ValueIsFilled(BudgetFlowItem) Then
		If Parameters.Property("ArbitraryIndicator") Then
			Title = NStr("vi = 'Toán hạng: <Mục ngân sách có phát sinh>';
						|ru = 'Операнд: <Статьи бюджетирования, по которым есть обороты>';
						|en = 'Operand: <Budgeting items with turnovers>'; fa = 'Operand: <Budgeting items with turnovers>';
						|it = 'Operando: <Voci di budgeting per le quali vi è fatturato>';
						|pl = 'Operand: <Pozycje budżetowania, dla których istnieją obroty>';
						|tr = 'İşlenen: <Filtrelerin kendilerine göre ayarlandığı bütçeleme kalemleri>'");
		Else
			Title = NStr("vi = '<Các khoản mục ngân sách có phát sinh>';
						|ru = '<Статьи бюджетирования, по которым есть обороты>';
						|en = '<Items of budgeting with turnovers>'; fa = '<Items of budgeting with turnovers>';
						|it = '<Voci di budgeting per le quali vi è fatturato>';
						|pl = '<Pozycje budżetowania, dla których istnieją obroty>';
						|tr = '<Filtrelerin kendilerine göre ayarlandığı bütçeleme kalemleri>'");
		EndIf;
		Items.GroupBudgetItem.Visible = False;
	ElsIf TypeOf(BudgetFlowItem) = Type("CatalogRef.BudgetBalanceItems") Then
		If Parameters.Property("ArbitraryIndicator") Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Toán tử: Số liệu ngân sách ""%1""';
					|ru = 'Операнд: Показатель бюджетов ""%1""';
					|en = 'Operand: Budget balance item ""%1""'; fa = 'Operand: Budget balance item ""%1""';
					|it = 'Operando: Indicatore di bilanci ""%1""';
					|pl = 'Operand: Wskaźnik budżetów ""%1""';
					|tr = 'İşlenen: Bütçe kalemi ""%1""'"),
				BudgetFlowItem);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Số liệu ngân sách ""%1""';
					|ru = 'Показатель бюджетов ""%1""';
					|en = 'Budget balance item ""%1""'; fa = 'Budget balance item ""%1""';
					|it = 'Indicatore di bilanci ""%1""';
					|pl = 'Wskaźnik budżetów ""%1""';
					|tr = 'Bütçe kalemi ""%1""'"),
				BudgetFlowItem);
		EndIf;
		Items.PictureBudgetItem.Visible = False;
		Items.BudgetIndicatorPicture.Visible = True;
	Else
		If Parameters.Property("ArbitraryIndicator") Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Toán hạng: %1 ""%2""';
					|ru = 'Операнд: %1 ""%2""';
					|en = 'Operand: %1 ""%2""'; fa = 'Operand: %1 ""%2""';
					|it = 'Operando: %1 ""%2""';
					|pl = 'Operand: %1 ""%2""';
					|tr = 'İşlenen: %1 ""%2""'"),
				Parameters.ItemKind,
				BudgetFlowItem);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 ""%2""';
					|ru = '%1 ""%2""';
					|en = '%1 ""%2""'; fa = '%1 ""%2""';
					|it = '%1 ""%2""';
					|pl = '%1 ""%2""';
					|tr = '%1 ""%2""'"),
				Parameters.ItemKind,
				BudgetFlowItem);
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(BudgetFlowItem) Or Common.ObjectAttributeValue(BudgetFlowItem, "RecordByQuantity") Then
		Items.DisplayedIndicators.ChoiceList.Add(Enums.TypesOfDisplayedBudgetReportIndicators.Count);
		If Not Parameters.Property("CellsSettings")
			And Not Parameters.Property("ArbitraryIndicator") Then
			Items.DisplayedIndicators.ChoiceList.Add(Enums.TypesOfDisplayedBudgetReportIndicators.QuantityAndAmount);
		EndIf;
	EndIf;
	
	PrivilegedModeRadioButton = Number(PrivilegedMode);
	
	If Not (Parameters.Property("CellsSettings")
		Or Parameters.Property("ArbitraryIndicator")) Then
		
		ItemsTree = FormDataToValue(Parameters.ReportItems, Type("ValueTree"));
		AddressOfReportItems = PutToTempStorage(ItemsTree, UUID);
		AddressOfEditedItem = ItemAddressInStorage;
		ItemTableAddress = Undefined;
		
	Else
		
		AddressOfReportItems = Parameters.AddressOfReportItems;
		If Parameters.Property("ArbitraryIndicator") Then
			AddressOfEditedItem = Parameters.AddressOfEditedItem;
		Else
			AddressOfEditedItem = ItemAddressInStorage;
		EndIf;
		ItemTableAddress = Parameters.ItemTableAddress;
		
	EndIf;
	
	FilterDefinitionParameters = New Structure;
	FilterDefinitionParameters.Insert("AddressOfEditedItem", AddressOfEditedItem);
	FilterDefinitionParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	If ValueIsFilled(ItemTableAddress) Then
		FilterDefinitionParameters.Insert("ItemTableAddress", ItemTableAddress);
	EndIf;
	
	FilterAvailabilityParameters = BudgetReportingCacheCalculationServer.FilterAvailabilityParameters(Undefined, FilterDefinitionParameters);
	
	For Each KeyAndValue In FilterAvailabilityParameters Do
		If KeyAndValue.Key = "Scenario" Then
			Items.UseTheDefaultFilterScenario.Visible = KeyAndValue.Value;
		ElsIf KeyAndValue.Key = "Organization" Then
			Items.UseTheFilterByOrganization.Visible = KeyAndValue.Value;
		ElsIf KeyAndValue.Key = "Department" Then
			Items.UseTheDefaultFilterDepartment.Visible = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	Items.SettingThePeriodOffset.Title = BudgetReportingClientServer.OffsetPresentation(ThisObject);
	
	If Parameters.Property("ParentItemKind")
	   And Parameters.ParentItemKind = Enums.FinancialReportItemKinds.DerivedItem
	   And Parameters.Property("UseToEnterPlan")
	   And Parameters.UseToEnterPlan Then
		Items.ExcludeEnteredDocumentDataDuringCalculation.Visible = True;
	Else
		Items.ExcludeEnteredDocumentDataDuringCalculation.Visible = False;
	EndIf;
	
	FormControl(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CheckingSelectionByAvailabilityParameters();
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_BudgetFlowItems" Then
		If ValueIsFilled(Object.Ref) Then
			Read();
		Else
			Object.NameForPrinting = Parameter;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure SettingThePeriodOffsetClick(Item)
	
	CallbackDescription = New CallbackDescription("SetOffsetPeriod", ThisObject);
	OffsetParameters = BudgetReportingClientServer.ParametersForOpeningPeriodSettingsForm(ThisObject);
	
	OpenForm("Catalog.FinancialReportItems.Form.SetUpDataSourcePeriod",
														OffsetParameters,,,,,CallbackDescription);
	
EndProcedure

&AtClient
Procedure NotUseAFilterOnChange(Item)
	
	InstallSelectionOnServer();
	
EndProcedure

&AtClient
Procedure PresentationExpressionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	BudgetReportingClient.ChangingExpressionOfSortingViewInFormulaEditor(ThisObject,
		"PresentationExpression", Object.NameForPrinting);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinancialReportingClient.FinishEditingReportElement(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Form.Items.PresentationExpression.Visible = ValueIsFilled(Form.BudgetFlowItem);
	
	Form.Items.NameForPrinting.Enabled = IsBlankString(Form.PresentationExpression);
	
EndProcedure

&AtServer
Procedure CheckingSelectionByAvailabilityParameters()
	
	If Not Modified Then
		Return;
	EndIf;
	
	FilterDefinitionParameters = New Structure;
	FilterDefinitionParameters.Insert("AddressOfEditedItem", AddressOfEditedItem);
	FilterDefinitionParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	If ValueIsFilled(ItemTableAddress) Then
		FilterDefinitionParameters.Insert("ItemTableAddress", ItemTableAddress);
	EndIf;
	
	FilterAvailabilityParameters = BudgetReportingCacheCalculationServer.FilterAvailabilityParameters(Undefined, FilterDefinitionParameters);
	FilterAvailabilityParameters.Insert("Status", UseStatusFilter);
	
	For Each KeyAndValue In FilterAvailabilityParameters Do
		ListOfSelectionElements = New ValueList;
		SearchForSelectionElements = False;
		If KeyAndValue.Key = "Scenario"
			And Not KeyAndValue.Value
			And UseFilterScenario Then
			SearchForSelectionElements = True;
		EndIf;
		If KeyAndValue.Key = "Organization"
			And Not KeyAndValue.Value
			And UseFilterByCompany Then
			SearchForSelectionElements = True;
		EndIf;
		If KeyAndValue.Key = "Department"
			And Not KeyAndValue.Value
			And UseFilterByDepartment Then
			SearchForSelectionElements = True;
		EndIf;
		If KeyAndValue.Key = "Status"
			And UseStatusFilter Then
			SearchForSelectionElements = True;
		EndIf;
		If SearchForSelectionElements Then
			ListOfSelectionElements = New ValueList;
			BudgetReportingCacheCalculationServer.FindSelectionByName(
				Composer.Settings,
				KeyAndValue.Key,
				ListOfSelectionElements,,
				False);
			
			// The intersection of selections in the column and in the add.selection. The filter usage flag has been enabled.
			// If the list of selection items is empty, it means that the user has cleared the selection,
			// it is necessary to disable the filter use flag.
			If ListOfSelectionElements.Count() = 0 Then
				If KeyAndValue.Key = "Scenario" Then
					UseFilterScenario = 0;
				ElsIf KeyAndValue.Key = "Organization" Then
					UseFilterByCompany = 0;
				ElsIf KeyAndValue.Key = "Department" Then
					UseFilterByDepartment = 0;
				ElsIf KeyAndValue.Key = "Status" Then
					UseStatusFilter = False;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure SetOffsetPeriod(Result, AdditionalParameters) Export
	
	BudgetReportingClient.SetOffsetPeriod(Object, ThisObject, Result);
	
EndProcedure

&AtServer
Procedure InstallSelectionOnServer()
	
	Catalogs.FinancialReportItems.SetFilterSettings(ThisObject, Composer, Object.ItemKind, Composer.Settings);
	
EndProcedure

&AtClient
Procedure PrivilegedModeOnChange(Item)
	
	PrivilegedMode = Boolean(PrivilegedModeRadioButton);
	
EndProcedure

#EndRegion

