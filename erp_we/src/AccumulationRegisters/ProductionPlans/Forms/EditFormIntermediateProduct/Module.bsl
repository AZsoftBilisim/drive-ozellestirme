#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("Scenario", Scenario);
	Parameters.Property("DemandForMaterials", DemandForMaterials);
	
	ReadData();
	
	SetSpecificationSelectionParameters();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ListOfAdjustments);
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	For RowIndex = 0 To ListOfAdjustments.Count() - 1 Do
		
		RowData = ListOfAdjustments[RowIndex];
		
		LineNumber = RowIndex + 1;
		DataPath = StrTemplate("ListOfAdjustments[%1].Products", Format(RowIndex, "NZ=0; NG=0"));
		
		If Not ValueIsFilled(RowData.BillOfMaterials) Then
			MessageText = StrTemplate(NStr("vi = 'Chưa điền trường ""Bảng kê chi tiết"" trong dòng %1.';
											|ru = 'Не заполнено поле ""Спецификация"" в строке %1.';
											|en = '""BOM"" is required in line %1.'; fa = '""BOM"" is required in line %1.';
											|it = 'Non è stato compilato il campo ""Specifica"" nella riga %1.';
											|pl = 'Nie zostało wypełnione pole ""Specyfikacja"" w wierszu %1.';
											|tr = 'Satırdaki ""Ürün reçetesi"" alanı doldurulmadı %1.'"), LineNumber);
			CommonClientServer.MessageToUser(MessageText,, DataPath,, Cancel);
		EndIf;
		
		If Not ValueIsFilled(RowData.DateOfOrderReleaseAndProductionIssue) Then
			MessageText = StrTemplate(NStr("vi = 'Chưa điền ""Ngày khởi động"" trong dòng %1.';
											|ru = 'Не заполнена поле ""Дата запуска"" в строке %1.';
											|en = '""Launch date"" field in line %1 is not filled in.'; fa = '""Launch date"" field in line %1 is not filled in.';
											|it = 'Non è stato compilato il campo ""Data di lancio"" nella riga %1.';
											|pl = 'Nie zostało wypełnione pole ""Data uruchomienia"" w wierszu %1.';
											|tr = '%1 satırda ""Başlangıç tarihi"" alanı doldurulmadı.'"), LineNumber);
			CommonClientServer.MessageToUser(MessageText,, DataPath,, Cancel);
		EndIf;
		
		If Not ValueIsFilled(RowData.Period) Then
			MessageText = StrTemplate(NStr("vi = 'Chưa điền ""Ngày xuất xưởng"" trong dòng %1.';
											|ru = 'Не заполнена поле ""Дата выпуска"" в строке %1.';
											|en = '""Release date"" field in line %1 is not filled in.'; fa = '""Release date"" field in line %1 is not filled in.';
											|it = 'Non è stato compilato il campo ""Data di rilascio"" nella riga %1.';
											|pl = 'Nie zostało wypełnione pole ""Data produkcji"" w wierszu %1.';
											|tr = 'Satırdaki ""Çıkış tarihi"" alanı doldurulmadı %1.'"), LineNumber);
			CommonClientServer.MessageToUser(MessageText,, DataPath,, Cancel);
		EndIf;
		
		If RowData.DateOfOrderReleaseAndProductionIssue > RowData.Period
			And Not Cancel Then
			MessageText = StrTemplate(NStr("vi = 'Sai trường ""Ngày xuất xưởng"" trong dòng %1.';
											|ru = 'Некорректно поле ""Дата выпуска"" в строке %1.';
											|en = '""Launch date"" field in line %1 is incorrect.'; fa = '""Launch date"" field in line %1 is incorrect.';
											|it = 'Il campo ""Data di rilascio"" nella riga %1 non è corretto.';
											|pl = 'Niepoprawne pole ""Data produkcji"" w wierszu %1.';
											|tr = 'Satırdaki ""Çıkış tarihi"" alanı hatalı %1.'"), LineNumber);
			CommonClientServer.MessageToUser(MessageText,, DataPath,, Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseWithoutConfirmation And Modified Then
		
		StandardProcessing = False;
		Cancel = True;
		If Exit Then
			WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
			Return;
		EndIf;
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Đóng';
												|ru = 'Закрыть';
												|en = 'Close'; fa = 'بستن';
												|it = 'Chiudere';
												|pl = 'Zamknij';
												|tr = 'Kapat'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		
		QueryText = NStr("vi = 'Sẽ mất những thay đổi đưa vào. Tiếp tục?';
						|ru = 'Внесенные изменения будут потеряны. Продолжить?';
						|en = 'Changes will be lost. Continue?'; fa = 'Changes will be lost. Continue?';
						|it = 'Modifiche apportate saranno perse. Continuare?';
						|pl = 'Wprowadzone zmiany zostaną utracone. Kontynuować?';
						|tr = 'Girilen düzenlemeler kaybedilecek. Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("QuestionOfClosure", ThisObject), QueryText, Buttons);
		
	EndIf;

EndProcedure

&AtClient
Procedure QuestionOfClosure(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		CloseWithoutConfirmation = True;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure RecordAdjustmentOnServer()
	
	ModifiedRows = ModifiedRows();
	
	If ModifiedRows.Count() > 0 Then
	
		BeginTransaction();
		Try
			
			InformationRegisters.ProductionPlanAdjustmentContents.AddToQueue(Parameters.ProductionPlan, ModifiedRows);
			
			InformationRegisters.QueueOfProductionPlanCalculation.AddJob(Scenario , Parameters.ProductionPlan);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			Raise ErrorText;
			
		EndTry;
		
	EndIf;
	
EndProcedure
&AtClient
Procedure WriteDownTheAdjustment(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	RecordAdjustmentOnServer();
	CloseWithoutConfirmation = True;
	Close(True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BillOfMaterialsOnChange(Item)
	
	CurrentData = Items.ListOfAdjustments.CurrentData;
	
	WhenChangingRowData(CurrentData);
	
	CalculateLaunchDate(ThisForm, CurrentData);
	
EndProcedure

&AtClient
Procedure DateOfOrderReleaseAndProductionIssueOnChange(Item)
	
	WhenChangingRowData(Items.ListOfAdjustments.CurrentData);
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	
	CurrentData = Items.ListOfAdjustments.CurrentData;
	
	WhenChangingRowData(CurrentData);
	
	PeriodForChangesOnServer(Items.ListOfAdjustments.CurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	WhenChangingRowData(Items.ListOfAdjustments.CurrentData);
	
EndProcedure

&AtClient
Procedure CommentOnChange(Item)
	
	WhenChangingRowData(Items.ListOfAdjustments.CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfAdjustments

&AtClient
Procedure ListOfAdjustmentsOnActivateRow(Item)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ListOfAdjustments, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure PeriodForChangesOnServer(RowID, CachedValues)
	
	CurrentData = ListOfAdjustments.FindByID(RowID);
	
	StructureOfActions = New Structure;
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Undefined, CurrentData, BOMSelectionParameters, ThisForm);
	FillParameters.ProductData.ProductionStart = CurrentData.Period;
		
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
		
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	CalculateLaunchDate(ThisForm, CurrentData);
	
EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm,
																			"ListOfAdjustmentsCharacteristic",
																			"ListOfAdjustments.ItemVariantsAreUsed");
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																			"ListOfAdjustmentsPurpose",
																			"ListOfAdjustments.ItemsType",
																			False);
																			
	
EndProcedure

&AtServer
Procedure ReadData()
	
	If Not ValueIsFilled(Parameters.IDs) Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	RowFilter.Recorder AS Recorder,
	|	RowFilter.LineNumber AS LineNumber
	|INTO RowFilter
	|FROM
	|	&RowFilter AS RowFilter
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|INTO ProductionPlans
	|FROM
	|	AccumulationRegister.ProductionPlans AS ProductionPlans
	|WHERE
	|	(ProductionPlans.Recorder, ProductionPlans.LineNumber) IN
	|			(SELECT
	|				RowFilter.Recorder,
	|				RowFilter.LineNumber
	|			FROM
	|				RowFilter AS RowFilter)
	|	
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	ProductionPlans.ProductionPlan         AS ProductionPlan,
	|	ProductionPlans.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	ProductionPlans.Purpose               AS Purpose,
	|	ProductionPlans.Products             AS Products,
	|	ProductionPlans.Characteristic           AS Characteristic,
	|	
	|	SUM(ISNULL(MaterialConsumptionPlans.Count, 0)) AS Count,
	|	SUM(ISNULL(MaterialConsumptionPlans.ToOrder, 0)) AS ToOrder
	|	
	|INTO ConsumptionPlans
	|FROM
	|	ProductionPlans AS ProductionPlans
	|	
	|		LEFT JOIN AccumulationRegister.MaterialConsumptionPlans AS MaterialConsumptionPlans
	|		   ON ProductionPlans.ProductionPlan         = MaterialConsumptionPlans.ProductionPlan
	|			AND ProductionPlans.ProductionIssueDateOfIntermediateProducts = MaterialConsumptionPlans.Period
	|			AND ProductionPlans.Purpose               = MaterialConsumptionPlans.Purpose
	|			AND ProductionPlans.Products             = MaterialConsumptionPlans.Products
	|			AND ProductionPlans.Characteristic           = MaterialConsumptionPlans.Characteristic
	|	
	|GROUP BY
	|	ProductionPlans.ProductionPlan,
	|	ProductionPlans.ProductionIssueDateOfIntermediateProducts,
	|	ProductionPlans.Purpose,
	|	ProductionPlans.Products,
	|	ProductionPlans.Characteristic
	|
	|HAVING
	|	SUM(ISNULL(MaterialConsumptionPlans.Count, 0)) <> 0 OR SUM(ISNULL(MaterialConsumptionPlans.ToOrder, 0)) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*,
	|
	|	ProductionPlans.Purpose.LineOfBusiness AS LineOfBusiness,
	|	ProductionPlans.BillOfMaterials AS SpecificationBeforeChange,
	|	ProductionPlans.Period AS PeriodBeforeChange,
	|	ProductionPlans.DateOfOrderReleaseAndProductionIssue AS ReleaseStartDateBeforeChange,
	|
	|	ISNULL(ConsumptionPlans.Count, 0) AS InitialDemand,
	|	ISNULL(ConsumptionPlans.ToOrder, 0) AS InitialDemandForOrder
	|FROM
	|	ProductionPlans AS ProductionPlans
	|		LEFT JOIN ConsumptionPlans AS ConsumptionPlans
	|		   ON ProductionPlans.ProductionIssueDateOfIntermediateProducts = ConsumptionPlans.ProductionIssueDateOfIntermediateProducts
	|			AND ProductionPlans.ProductionPlan         = ConsumptionPlans.ProductionPlan
	|			AND ProductionPlans.Purpose               = ConsumptionPlans.Purpose
	|			AND ProductionPlans.Products             = ConsumptionPlans.Products
	|			AND ProductionPlans.Characteristic           = ConsumptionPlans.Characteristic
	|	
	|");
	
	RowFilter = New ValueTable();
	RowFilter.Columns.Add("Recorder", New TypeDescription("DocumentRef.RegisterProductionPlan"));
	RowFilter.Columns.Add("LineNumber", New TypeDescription("Number"));

	For Each RecordKey In Parameters.IDs Do
		FillPropertyValues(RowFilter.Add(), RecordKey);
	EndDo;
	
	Query.SetParameter("RowFilter", RowFilter);
	
	SetPrivilegedMode(True);
	ListOfAdjustments.Load(Query.Execute().Unload());
	SetPrivilegedMode(False);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(ListOfAdjustments, StructureOfActions);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ScriptParameters_ = Common.ObjectAttributesValues(
		Scenario,
		"PlanningByAssignments");
	
	ThereIsDataToAdjust = ( ListOfAdjustments.Count() > 0 );
	
	If ThereIsDataToAdjust Then
		Items.Pages.CurrentPage = Items.PageGeneral;
	Else
		Items.Pages.CurrentPage = Items.ErrorPage;
	EndIf;
	
	Items.FormWrite.Enabled = ThereIsDataToAdjust;
	
	ShowDestinations = ScriptParameters_.PlanningByAssignments And GetFunctionalOption("UseOrderSupplyWithAssignment");
	Items.ListOfAdjustmentsPurpose.Visible = ShowDestinations;
	
	PlanStatus = Common.ObjectAttributeValue(Parameters.ProductionPlan, "Status");
	Items.ForOrderGroup.Visible = PlanStatus = Enums.PlanStatuses.Upholded;
	
EndProcedure

&AtServer
Procedure SetSpecificationSelectionParameters()
	
	BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "ListOfAdjustments.Products";
	ChoiceParameterLinks.Characteristic          = "ListOfAdjustments.Characteristic";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "ListOfAdjustments.Department";
	ChoiceParameterLinks.LineOfBusiness = "ListOfAdjustments.LineOfBusiness";
	ChoiceParameterLinks.ProductionStart      = "PlanPeriodStart";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Items.ListOfAdjustments.CurrentData.BillOfMaterials", ChoiceParameterLinks);
	
	ProductDataManagement.SetSpecificationSelectionParameters(Items.BillOfMaterials, BOMSelectionParameters);
	
	PlanPeriodStart = Common.ObjectAttributeValue(Parameters.ProductionPlan, "BeginOfPeriod");
	
EndProcedure

&AtClient
Procedure WhenChangingRowData(RowData)
	
	If RowData = Undefined Then
		Return;
	EndIf;
	
	RowData.HasChanges = True;
	RowData.ManualAdjustment = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateLaunchDate(Form, CurrentData)
	
	If ValueIsFilled(Form.Scenario)
		And ValueIsFilled(CurrentData.Period)
		And ValueIsFilled(CurrentData.BillOfMaterials) Then
		
		FieldsNames = New Structure("DateOfProduction, StartDate2", "Period", "DateOfOrderReleaseAndProductionIssue");
		
		CurrentData.DateOfOrderReleaseAndProductionIssue = CalculateLaunchDateServer(Form.Scenario,
																		CurrentData.BillOfMaterials,
																		CurrentData.Period,
																		CurrentData.DateOfOrderReleaseAndProductionIssue,
																		ProcessingOfTabularFormsClientServer.LineCache(Form.Items.ListOfAdjustments, Form),
																		FieldsNames,
																		Form.DemandForMaterials);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculateLaunchDateServer(Scenario, BillOfMaterials, DateOfProduction, StartDate2, DataBeforeChange, FieldsNames, MethodOfCalculationOfMaterials)
	
	If ValueIsFilled(DataBeforeChange[FieldsNames.StartDate2])
		And ValueIsFilled(DataBeforeChange[FieldsNames.DateOfProduction])
		And ValueIsFilled(DataBeforeChange.BillOfMaterials) Then
		
		RegulatoryLaunchDateBeforeChange = Planning.CalculateLaunchDate(
			Scenario,
			DataBeforeChange[FieldsNames.DateOfProduction],
			DataBeforeChange.BillOfMaterials,
			MethodOfCalculationOfMaterials);
			
		If RegulatoryLaunchDateBeforeChange <> DataBeforeChange[FieldsNames.StartDate2] Then
			
			Return StartDate2;
			
		EndIf;
		
	EndIf;

	Return Planning.CalculateLaunchDate(Scenario, DateOfProduction, BillOfMaterials, MethodOfCalculationOfMaterials);
	
EndFunction

&AtServer
Function ModifiedRows()
	
	EventDate = CurrentSessionDate();
	Author = Users.CurrentUser();
	
	UnloadingStructure = New Structure;
	UnloadingStructure.Insert("ColumnsByValue", New Structure("AdjustmentDate, AdjustmentAuthor", EventDate, Author));
	UnloadingStructure.Insert("OtherColumnNames", New Structure("DateOfOrderReleaseAndProductionIssue, Period", "StartDate2", "DateOfProduction"));
	UnloadingStructure.Insert("RowFilter", New Structure("HasChanges", True));
	
	ModifiedRows = TMCommonUse.ExportValuesTable(
		ListOfAdjustments,
		UnloadingStructure.RowFilter,
		"ProductionPlan,
		|
		|Products,
		|Characteristic,
		|Purpose,
		|ProductionIssueDateOfIntermediateProducts,
		|
		|BillOfMaterials,
		|
		|DateOfOrderReleaseAndProductionIssue,
		|Period,
		|
		|Count,
		|ToOrder,
		|
		|InitialDemand,
		|InitialDemandForOrder,
		|
		|Comment
		|",
		UnloadingStructure.ColumnsByValue,
		UnloadingStructure.OtherColumnNames);
	
	Return ModifiedRows;

EndFunction

#EndRegion

