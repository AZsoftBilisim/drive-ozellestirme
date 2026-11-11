
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters, "CostGenerationModel, RecordCostsByADocument, BillOfMaterials, AllocatedAccordingToRule");
	
	If Parameters.Property("ConfigurationIsRequired")
		And Parameters.ConfigurationIsRequired Then
		Modified = True;
	EndIf;
	
	If Parameters.Property("FilterParameters") Then
		
		If TypeOf(Parameters.FilterParameters) = Type("Array") Then
			
			For Each CurSelectionParameter In Parameters.FilterParameters Do
				FillPropertyValues(FilterParameters.Add(), CurSelectionParameter);
			EndDo;
			
		Else
			
			FillPropertyValues(FilterParameters.Add(), Parameters.FilterParameters);
			
		EndIf;
		
	EndIf;
	
	If CostGenerationModel = Enums.ModelTypesOfCosting.EmptyRef() Then
		CostGenerationModel = Enums.ModelTypesOfCosting.ReleaseAtCalculatedCost;
		RecordCostsByADocument = True;
	EndIf;
	
	BOMSelectionParameters = Documents.BackflushProduction.BOMSelectionParameters(New Structure());
	SetSpecificationHint();
	
	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.CostGenerationModels);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ModelOfFormationOfValueAtChange(True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		Cancel = True;
		StandardProcessing = False;
		
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisForm);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	Notify("CostGenerationModel_Update");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.ChoiceFormByItems" Then
		BillOfMaterials = ValueSelected;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductReleaseAtTheCalculatedCostOnChange(Item)
	
	ModelOfFormationOfValueAtChange();
	
EndProcedure

&AtClient
Procedure ProductionIssueAtFixedCostOnChange(Item)
	
	ModelOfFormationOfValueAtChange();
	
EndProcedure

&AtClient
Procedure RecordCostsByADocumentOnChange(Item)
	
	Items.BillOfMaterials.Enabled = RecordCostsByADocument;
	
	If Not RecordCostsByADocument Then
		BillOfMaterials = Undefined;
	EndIf;
	
	SetSpecificationHint();
	
EndProcedure

&AtClient
Procedure BillOfMaterialsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductData_2 = New Array;
	
	For Each CurProduct In FilterParameters Do
		
		ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		ProductData.Products            = CurProduct.Products;
		ProductData.Characteristic          = CurProduct.Characteristic;
		ProductData.LineOfBusiness = CurProduct.LineOfBusiness;
		
		ProductData_2.Add(ProductData);
		
	EndDo;
	
	ProductDataManagementClient.OpenFormForSelectingSpecificationsFromListOfProducts(ProductData_2, BOMSelectionParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.RegisterBackflushProduction.Form.FormSetUpCostGenerationModel.Command.WriteAndClose");
	// End StandardSubsystems.PerformanceMeasurement
	
	WriteAtServer();
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
EndProcedure

&AtServer
Procedure SetSpecificationHint()
	
	If RecordCostsByADocument Then
		Items.BillOfMaterials.InputHint = NStr("vi = '<bảng kê chi tiết các nguồn lực sản xuất chính>';
												|ru = '<основная спецификация>';
												|en = '<main BOM>'; fa = '<main BOM>';
												|it = '<specifica principale>';
												|pl = '<specyfikacja główna>';
												|tr = '<ana ürün reçetesi>'");
	Else
		Items.BillOfMaterials.InputHint = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		WriteAtServer();
		Close();
	ElsIf Result = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure ModelOfFormationOfValueAtChange(Initialize = False)

	If CostGenerationModel = PredefinedValue("Enum.ModelTypesOfCosting.ReleaseAtCalculatedCost") Then
		
		If Not Initialize Then
			RecordCostsByADocument	= True;
			AllocatedAccordingToRule		= Undefined;
		EndIf;
		
		Items.BillOfMaterials.Enabled				= True;
		Items.RecordCostsByADocument.Enabled	= True;
		Items.AllocatedAccordingToRule.Enabled		= False;
		
	ElsIf CostGenerationModel = PredefinedValue("Enum.ModelTypesOfCosting.ProductionIssueAtFixedCost") Then
		
		If Not Initialize Then
			RecordCostsByADocument	= False;
			BillOfMaterials				= Undefined;
		EndIf;
		
		Items.BillOfMaterials.Enabled				= False;
		Items.RecordCostsByADocument.Enabled	= False;
		Items.AllocatedAccordingToRule.Enabled		= True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteAtServer()
	
	For Each CurrFilter In FilterParameters Do
		
		Record = InformationRegisters.CostGenerationModels.CreateRecordManager();
		
		FillPropertyValues(Record, CurrFilter);
		
		Record.CostGenerationModel = CostGenerationModel;
		Record.AllocatedAccordingToRule = AllocatedAccordingToRule;
		Record.RecordCostsByADocument = RecordCostsByADocument;
		Record.BillOfMaterials = BillOfMaterials;
		
		Record.Write(True);
		
	EndDo;
	
	Modified = False;
	
EndProcedure

#EndRegion