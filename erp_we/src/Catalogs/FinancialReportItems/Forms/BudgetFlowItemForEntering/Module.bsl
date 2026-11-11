
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
	
	ObjectData = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	MainStorageID = Parameters.MainStorageID;
	LineIDOfReportItem = Parameters.LineIDOfReportItem;
	
	If Not ValueIsFilled(BudgetFlowItem) Then
		Title = NStr("vi = '<Các khoản mục ngân sách có phát sinh>';
					|ru = '<Статьи бюджетирования, по которым есть обороты>';
					|en = '<Items of budgeting with turnovers>'; fa = '<Items of budgeting with turnovers>';
					|it = '<Voci di budgeting per le quali vi è fatturato>';
					|pl = '<Pozycje budżetowania, dla których istnieją obroty>';
					|tr = '<Filtrelerin kendilerine göre ayarlandığı bütçeleme kalemleri>'");
	ElsIf TypeOf(BudgetFlowItem) = Type("CatalogRef.BudgetBalanceItems") Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Số liệu ngân sách ""%1""';
				|ru = 'Показатель бюджетов ""%1""';
				|en = 'Budget balance item ""%1""'; fa = 'Budget balance item ""%1""';
				|it = 'Indicatore di bilanci ""%1""';
				|pl = 'Wskaźnik budżetów ""%1""';
				|tr = 'Bütçe kalemi ""%1""'"),
			BudgetFlowItem);
		Items.PictureBudgetItem.Visible = False;
		Items.BudgetIndicatorPicture.Visible = True;
	Else
		Title = String(Parameters.ItemKind) + ": " + BudgetFlowItem;
	EndIf;
	
	If Not Parameters.Property("CellsSettings") Then
		// auto-calculation is available only in a complex table
		Items.FillingMethod.ChoiceList.Delete(1);
		
		ItemsTree = FormDataToValue(Parameters.ReportItems, Type("ValueTree"));
		AddressOfReportItems = PutToTempStorage(ItemsTree, UUID);
		ItemTableAddress = Undefined;
	Else
		ItemTableAddress = Parameters.ItemTableAddress;
		AddressOfReportItems = Parameters.AddressOfReportItems;
	EndIf;
	
	If Not ValueIsFilled(BudgetFlowItem) Or Common.ObjectAttributeValue(BudgetFlowItem, "RecordByQuantity") Then
		Items.DisplayedIndicators.ChoiceList.Add(Enums.TypesOfDisplayedBudgetReportIndicators.Count);
		If Not Parameters.Property("CellsSettings")
			And Not Parameters.Property("ArbitraryIndicator") Then
			Items.DisplayedIndicators.ChoiceList.Add(Enums.TypesOfDisplayedBudgetReportIndicators.QuantityAndAmount);
		EndIf;
	EndIf;
	
	FormulaOperands.Clear();
	For Each OperandString_ In ObjectData.FormulaOperands Do
		NewRow = FormulaOperands.Add();
		FillPropertyValues(NewRow, OperandString_);
	EndDo;
	For Each StringRule In ObjectData.CalculationsRules Do
		NewRow = CalculationsRules.Add();
		FillPropertyValues(NewRow, StringRule);
	EndDo;

	FormControl(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(Formula) Then
		CurrentObject.HasSettings = True;
	EndIf;
	
	If StrStartsWith(Formula, "<") And StrEndsWith(Formula, ">") Then
		Formula = "";
	EndIf;
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel);
	
	If ValueIsFilled(ItemAddressInStorage) Then
		ElementStructure = GetFromTempStorage(ItemAddressInStorage);
		ElementStructure.FormulaOperands.Clear();
		For Each OperandString_ In FormulaOperands Do
			If Not ValueIsFilled(OperandString_.AddressOfItemStructure) Then
				OperandString_.AddressOfItemStructure = 
					BudgetReportingClientServer.PlaceItemInStorage(OperandString_.Operand, MainStorageID);
			EndIf;
			FillPropertyValues(ElementStructure.FormulaOperands.Add(), OperandString_);
		EndDo;
		ElementStructure.CalculationsRules.Clear();
		For Each StringRule In CalculationsRules Do
			FillPropertyValues(ElementStructure.CalculationsRules.Add(), StringRule);
		EndDo;
		ElementStructure.Insert("ThereIsPrivilegedMode", ThereIsPrivilegedMode);
		PutToTempStorage(ElementStructure, ItemAddressInStorage);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FormControl(ThisObject);
	
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
Procedure FormulaClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If StrStartsWith(Formula, "<") And StrEndsWith(Formula, ">") Then
		Formula = "";
	EndIf;
	
	If FillingMethod = 3 Then
		ViewOfSettingElement = PredefinedValue("Enum.FinancialReportItemKinds.SetUpCalculationRules");
		AddressOfSettingsItemInStorage = GetAddressOfTemporaryObjectForSettingUpCalculationRules();
	Else
		ViewOfSettingElement = PredefinedValue("Enum.FinancialReportItemKinds.DerivedItem");
		AddressOfSettingsItemInStorage = GetAddressOfTemporaryObjectForEditingFormula();
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("ItemKind",                      ViewOfSettingElement);
	FormParameters.Insert("ItemAddressInStorage",          AddressOfSettingsItemInStorage);
	FormParameters.Insert("AddressOfEditedItem",      ItemAddressInStorage);
	FormParameters.Insert("MainStorageID",   MainStorageID);
	FormParameters.Insert("UseToEnterPlan",        UseToEnterPlan);
	FormParameters.Insert("FillingMethod",                 FillingMethod);
	FormParameters.Insert("ItemTableAddress",            ItemTableAddress);
	FormParameters.Insert("AddressOfReportItems",             AddressOfReportItems);
	FormParameters.Insert("LocationOptionOfActualDataOffset", LocationOptionOfActualDataOffset);
	FormParameters.Insert("LineIDOfReportItem",LineIDOfReportItem);
	FormParameters.Insert("ParentItemKind",              Object.ItemKind);
	FormParameters.Insert("UseFilterScenario",     UseFilterScenario);
	FormParameters.Insert("UseFilterByCompany",  UseFilterByCompany);
	FormParameters.Insert("UseFilterByDepartment",UseFilterByDepartment);
	FormParameters.Insert("UseStatusFilter",      UseStatusFilter);
	
	Notification = New CallbackDescription("UpdateFieldAfterChangingElement", ThisObject, FormParameters);
	
	OpenForm("Catalog.FinancialReportItems.ObjectForm",
								FormParameters, ThisObject, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
			
EndProcedure

&AtClient
Procedure FillingMethodOnChange(Item)
	
	Formula = "";
	FormulaOperands.Clear();
	CalculationsRules.Clear();
	Composer = New DataCompositionSettingsComposer;
	If FillingMethod = 1 Then
		ExcludeEnteredDocumentDataDuringCalculation = False;
	EndIf;
	FormControl(ThisObject);
	
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
	
	AdditionalInfo = New Structure();
	AdditionalInfo.Insert("ThereIsPrivilegedMode", ThereIsPrivilegedMode);
	FinancialReportingClient.FinishEditingReportElement(ThisObject, AdditionalInfo);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	If Form.FillingMethod = 0 Then
		Form.Items.Formula.Hyperlink = False;
		If IsBlankString(Form.Formula) Then
			Form.Formula = "";
		EndIf;
	Else
		Form.Items.Formula.Hyperlink = True;
		If IsBlankString(Form.Formula) Then
			If Form.FillingMethod = 1 Then
				Form.Formula = NStr("vi = '<thiết lập tính toán tự động>';
									|ru = '<настроить авторасчет>';
									|en = '<configure autocalculation>'; fa = '<configure autocalculation>';
									|it = '<impostare calcolo automatico>';
									|pl = '<ustaw automatyczne rozliczenie>';
									|tr = '<otomatik hesaplamayı ayarla>'");
			ElsIf Form.FillingMethod = 2 Then
				Form.Formula = NStr("vi = '<cấu hình tự động điền>';
									|ru = '<настроить автозаполнение>';
									|en = '<configure autofilling>'; fa = '<configure autofilling>';
									|it = '<impostare compilazione automatica>';
									|pl = '<ustaw automatyczne wypełnienie>';
									|tr = '<otomatik doldurmayı ayarla>'");
			Else
				Form.Formula = NStr("vi = '<thiết lập nguyên tắc>';
									|ru = '<настроить правила>';
									|en = '<configure rules>'; fa = '<پیکربندی قواعد>';
									|it = '<impostare le regole>';
									|pl = '<ustaw reguły>';
									|tr = '<kuralları ayarla>'");
			EndIf;
		EndIf;
	EndIf;
	
	Form.Items.PresentationExpression.Visible = ValueIsFilled(Form.BudgetFlowItem);
	
	Form.Items.NameForPrinting.Enabled = IsBlankString(Form.PresentationExpression);
	
EndProcedure

&AtServer
Function GetAddressOfTemporaryObjectForEditingFormula()
	
	BufferObject = FinancialReportingClientServer.ReportElementStructure();
	BufferObject.NameForPrinting = Object.NameForPrinting;
	BufferObject.ItemKind = Enums.FinancialReportItemKinds.DerivedItem;
	FinancialReportingServerCall.SetValueOfAdditionalProps(BufferObject, "Formula", Formula);
	BufferObject.FormulaOperands = FormulaOperands.Unload();
	
	Return PutToTempStorage(BufferObject, UUID);
	
EndFunction

&AtServer
Function GetAddressOfTemporaryObjectForSettingUpCalculationRules()
	
	BufferObject = FinancialReportingClientServer.ReportElementStructure();
	BufferObject.NameForPrinting = Object.NameForPrinting;
	BufferObject.ItemKind = Enums.FinancialReportItemKinds.SetUpCalculationRules;
	FinancialReportingServerCall.SetValueOfAdditionalProps(BufferObject, "BudgetFlowItem", BudgetFlowItem);
	BufferObject.CalculationsRules = CalculationsRules.Unload();
	BufferObject.AdditionalSelection = New ValueStorage(Composer.GetSettings());
	
	Return PutToTempStorage(BufferObject, UUID);
	
EndFunction

&AtServer
Procedure ReadFormulaDataFromTemporaryStorage(Address)
	
	BufferObject = GetFromTempStorage(Address);
	If BufferObject.ItemKind = Enums.FinancialReportItemKinds.SetUpCalculationRules Then
		CalculationsRules.Load(BufferObject.CalculationsRules);
		NumberOfRules = CalculationsRules.Count();
		Formula = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'đã chọn quy tắc: %1';
																				|ru = 'выбрано правил: %1';
																				|en = 'Rules selected: %1'; fa = 'Rules selected: %1';
																				|it = 'Rules selected: %1';
																				|pl = 'Rules selected: %1';
																				|tr = 'seçilen kural: %1'"), NumberOfRules);
		Composer.LoadSettings(BufferObject.AdditionalSelection.Get());
	Else
		Formula = FinancialReportingServerCall.ValueOfAdditionalProps(BufferObject, "Formula");
		FormulaOperands.Load(BufferObject.FormulaOperands);
	EndIf;
	PrivilegedMode = FinancialReportingServerCall.ValueOfAdditionalProps(BufferObject, "PrivilegedMode");
 	
	If IsBlankString(Formula) Then
		If BufferObject.ItemKind = Enums.FinancialReportItemKinds.DerivedItem Then
			Formula = NStr("vi = '<cấu hình tự động điền>';
							|ru = '<настроить автозаполнение>';
							|en = '<configure autofilling>'; fa = '<configure autofilling>';
							|it = '<impostare compilazione automatica>';
							|pl = '<ustaw automatyczne wypełnienie>';
							|tr = '<otomatik doldurmayı ayarla>'");
		Else
			Formula = NStr("vi = '<thiết lập nguyên tắc>';
							|ru = '<настроить правила>';
							|en = '<configure rules>'; fa = '<پیکربندی قواعد>';
							|it = '<impostare le regole>';
							|pl = '<ustaw reguły>';
							|tr = '<kuralları ayarla>'");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFieldAfterChangingElement(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ReadFormulaDataFromTemporaryStorage(AdditionalParameters.ItemAddressInStorage);
		If Result.ItemKind = PredefinedValue("Enum.FinancialReportItemKinds.SetUpCalculationRules") Then
			FillPropertyValues(ThisObject, Result, "UseFilterByCompany, UseFilterByDepartment, UseFilterScenario");
		EndIf;
	EndIf;
	If Result <> Undefined And Result.Property("ThereIsPrivilegedMode") Then
		ThereIsPrivilegedMode = Result.ThereIsPrivilegedMode;
	EndIf;
	FormControl(ThisObject);
	
EndProcedure

#EndRegion