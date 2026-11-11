
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CannotSelectNewStages = Parameters.CannotSelectNewStages;
	OrderReferences = Parameters.OrderReferences;
	
	If ValueIsFilled(Parameters.Organization) Then
		Items.ReferencesOrganization.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.Partner) Then
		Items.ReferencesPartner.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.Department) Then
		Items.ReferencesDepartment.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.PurchaseForActivity) Then
		Items.ReferencesPurchaseForActivity.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.LineOfBusiness) Then
		Items.ReferencesLineOfBusiness.Visible = False;
	EndIf;
	
	If Parameters.ReadOnly Then
		Items.ReferencesMoveToDocument.Enabled = False;
		Items.ReferencesSelectAll_2.Enabled = False;
		Items.ReferencesClearAllIetmsCommand.Enabled = False;
		Items.References.ReadOnly = True;
	ElsIf Parameters.CannotSelectNewStages Then
		Items.ReferencesSelectAll_2.Enabled = False;
		Items.FilterPeriod.Visible = False;
	EndIf; 
	
	FillOutOrders_();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterPeriodOnChange(Item)
	FillOutOrders_();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReferences

&AtClient
Procedure ReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ReferencesReferenceOrderPresentation Then
		StandardProcessing = False;
		CurrentData = Items.References.CurrentData;
		ShowValue(, CurrentData.ReferenceOrder);
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	TheStructureOfTheSearch = New Structure("Check", True);
	StringsList = References.FindRows(TheStructureOfTheSearch);
	
	FillingData = ProcessingByThirdPartiesClient.DataForGeneratingOrdersToProcessors2_5(StringsList);
	
	If FillingData <> Undefined Then
		Close(FillingData);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAll_2(Command)
	
	For Each CurrentData In References Do
		CurrentData.Check = True;
	EndDo; 
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	For Each CurrentData In References Do
		CurrentData.Check = False;
	EndDo; 
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm,
		"ReferencesCharacteristic",
		"References.ItemVariantsAreUsed");
	
	// The partner is not specified
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("References.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	// The start date is overdue
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesBegin.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("References.LaunchDateIsOverdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
EndProcedure

&AtServer
Procedure FillOutOrders_()
	
	References.Clear();
	
	QueryText = 
	// Stages specified in the order
	"SELECT ALLOWED
	|	TRUE AS Check,
	|	DocProductionStage.Ref AS ReferenceOrder,
	|	DocProductionStage.Number AS OrderNumber__,
	|	DocProductionStage.Date AS Order_Date,
	|	DocProductionStage.Organization AS Organization,
	|	DocProductionStage.Department AS Department,
	|	DocProductionStage.ProductionIssueForActivity AS PurchaseForActivity,
	|	&Partner AS Partner,
	|	DocProductionStage.ProductionLot.MainProductProducts AS Products,
	|	DocProductionStage.ProductionLot.MainProductCharacteristic AS Characteristic,
	|	CASE
	|		WHEN &PlannedStagesOfProduction
	|				AND NOT ProductionStages.Stage IS NULL
	|			THEN ProductionStages.Begin
	|		WHEN TargetOrderStructureSchedule.Begin IS NOT NULL
	|			THEN TargetOrderStructureSchedule.Begin
	|		ELSE DATEADD(DocProductionStage.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(NormativeStagesOfProduction.DurationBeforeStart, 0))
	|	END AS Begin,
	|	DocProductionStage.StageName AS StagePresentation,
	|	DocProductionStage.BillOfMaterials.Presentation AS BillOfMaterialsPresentation,
	|	ISNULL(DocProductionStage.BillOfMaterials.MultiStageProductionProcess, FALSE) AS MultiStageProductionProcess,
	|	CASE
	|		WHEN &PlannedStagesOfProduction
	|				AND NOT ProductionStages.Stage IS NULL
	|			THEN ProductionStages.Begin < &CurrentDate
	|		WHEN TargetOrderStructureSchedule.Begin IS NOT NULL
	|			THEN TargetOrderStructureSchedule.Begin < &CurrentDate
	|		ELSE DATEADD(DocProductionStage.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(NormativeStagesOfProduction.DurationBeforeStart, 0)) < &CurrentDate
	|	END AS LaunchDateIsOverdue,
	|	DocProductionStage.LineOfBusiness AS LineOfBusiness,
	|	DocProductionStage.GoodsReceiptOption AS GoodsReceiptOption,
	|	DocProductionStage.DynamicStructure AS DynamicStructure
	|FROM
	|	Document.ProductionStage2_2 AS DocProductionStage
	|	
	|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ProductionStages
	|	ON &PlannedStagesOfProduction
	|		AND ProductionStages.ProductionOrder = DocProductionStage.ReferenceOrder
	|		AND ProductionStages.Stage = DocProductionStage.Ref
	|		AND ProductionStages.ScheduleStatus = &ScheduleStatus
	|	
	|	LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS NormativeStagesOfProduction
	|	ON DocProductionStage.Ref = NormativeStagesOfProduction.ProductionStage
	|
	|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS TargetOrderStructureSchedule
	|	ON NOT &PlannedStagesOfProduction
	|		AND DocProductionStage.Ref = TargetOrderStructureSchedule.Stage
	|
	|WHERE
	|	DocProductionStage.Ref IN(&OrderReferences)
	|	AND DocProductionStage.ProductionByThirdParty
	|
	|UNION ALL
	|
	// Stages not specified in the order
	|SELECT
	|	FALSE AS Check,
	|	DocProductionStage.Ref,
	|	DocProductionStage.Number,
	|	DocProductionStage.Date,
	|	DocProductionStage.Organization AS Organization,
	|	DocProductionStage.Department,
	|	DocProductionStage.ProductionIssueForActivity AS PurchaseForActivity,
	|	DocProductionStage.Stage.Partner,
	|	DocProductionStage.ProductionLot.MainProductProducts AS Products,
	|	DocProductionStage.ProductionLot.MainProductCharacteristic AS Characteristic,
	|	CASE
	|		WHEN &PlannedStagesOfProduction
	|				AND NOT ProductionStages.Stage IS NULL
	|			THEN ProductionStages.Begin
	|		WHEN TargetOrderStructureSchedule.Begin IS NOT NULL
	|			THEN TargetOrderStructureSchedule.Begin
	|		ELSE DATEADD(DocProductionStage.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(NormativeStagesOfProduction.DurationBeforeStart, 0))
	|	END,
	|	DocProductionStage.StageName,
	|	DocProductionStage.BillOfMaterials.Presentation,
	|	ISNULL(DocProductionStage.BillOfMaterials.MultiStageProductionProcess, FALSE),
	|	CASE
	|		WHEN &PlannedStagesOfProduction
	|				AND NOT ProductionStages.Stage IS NULL
	|			THEN ProductionStages.Begin < &CurrentDate
	|		WHEN TargetOrderStructureSchedule.Begin IS NOT NULL
	|			THEN TargetOrderStructureSchedule.Begin < &CurrentDate
	|		ELSE DATEADD(DocProductionStage.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(NormativeStagesOfProduction.DurationBeforeStart, 0)) < &CurrentDate
	|	END,
	|	DocProductionStage.LineOfBusiness,
	|	DocProductionStage.GoodsReceiptOption AS GoodsReceiptOption,
	|	DocProductionStage.DynamicStructure AS DynamicStructure
	|FROM
	|	Document.ProductionStage2_2 AS DocProductionStage
	|
	|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ProductionStages
	|		ON &PlannedStagesOfProduction
	|			AND ProductionStages.ProductionOrder = DocProductionStage.ReferenceOrder
	|			AND ProductionStages.Stage = DocProductionStage.Ref
	|			AND ProductionStages.ScheduleStatus = &ScheduleStatus
	|
	|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS NormativeStagesOfProduction
	|		ON DocProductionStage.Ref = NormativeStagesOfProduction.ProductionStage
	|
	|		LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS TargetOrderStructureSchedule
	|		ON NOT &PlannedStagesOfProduction
	|			AND DocProductionStage.Ref = TargetOrderStructureSchedule.Stage
	|WHERE
	|	NOT &CannotSelectNewStages
	|	AND NOT DocProductionStage.Ref IN (&OrderReferences)
	|	AND NOT DocProductionStage.Status IN
	|		(VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated),
	|		VALUE(Enum.StatusesOfProductionStages2_2.Generated1))
	|	AND DocProductionStage.ProductionByThirdParty
	|	AND DocProductionStage.Posted
	|	AND (&StartDate = DATETIME(1, 1, 1)
	|			OR CASE
	|				WHEN &PlannedStagesOfProduction
	|						AND NOT ProductionStages.Stage IS NULL
	|					THEN ProductionStages.Begin
	|				ELSE DATEADD(DocProductionStage.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(NormativeStagesOfProduction.DurationBeforeStart, 0))
	|			END >= &StartDate)
	|	AND (&EndDate = DATETIME(1, 1, 1)
	|			OR CASE
	|				WHEN &PlannedStagesOfProduction
	|						AND NOT ProductionStages.Stage IS NULL
	|					THEN ProductionStages.Begin
	|				ELSE DATEADD(DocProductionStage.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(NormativeStagesOfProduction.DurationBeforeStart, 0))
	|			END <= &EndDate)
	|	AND (DocProductionStage.SubcontractOrder = UNDEFINED
	|			OR DocProductionStage.SubcontractOrder = &ProcessorOrder)
	|	AND (&Organization = VALUE(Catalog.Companies.EmptyRef)
	|			OR DocProductionStage.Organization = &Organization)
	|	AND (&Partner = VALUE(Catalog.Partners.EmptyRef)
	|			OR DocProductionStage.Stage.Partner = &Partner
	|			OR ISNULL(DocProductionStage.Stage.Partner, VALUE(Catalog.Partners.EmptyRef)) = VALUE(Catalog.Partners.EmptyRef))
	|	AND (&Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			OR DocProductionStage.Department = &Department)
	|	AND (&PurchaseForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			OR DocProductionStage.ProductionIssueForActivity = &PurchaseForActivity)
	|	AND (&LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			OR DocProductionStage.LineOfBusiness = &LineOfBusiness)
	|	AND (&DynamicStructure = UNDEFINED
	|			OR DocProductionStage.DynamicStructure = &DynamicStructure)
	|";
	
	OrderTemplate_1 = NStr("vi = 'Công đoạn số %1 ngày %2 (%3)';
							|ru = 'Этап № %1 от %2 (%3)';
							|en = 'Stage No. %1 dated %2 (%3)'; fa = 'Stage No. %1 dated %2 (%3)';
							|it = 'Fase №%1 di %2 (%3)';
							|pl = 'Etap nr %1 z dn. %2 (%3)';
							|tr = '%2 tarihli %1 numaralı aşama (%3)'");
	
	Query = New Query(QueryText);
	Query.SetParameter("CurrentDate",					CurrentSessionDate());
	Query.SetParameter("ProcessorOrder",				Parameters.ProcessorOrder);
	Query.SetParameter("Organization",					Parameters.Organization);
	Query.SetParameter("Partner",						Parameters.Partner);
	Query.SetParameter("Department",					Parameters.Department);
	Query.SetParameter("LineOfBusiness",		Parameters.LineOfBusiness);
	Query.SetParameter("PurchaseForActivity",			Parameters.PurchaseForActivity);
	Query.SetParameter("CannotSelectNewStages",		CannotSelectNewStages);
	Query.SetParameter("StartDate",						FilterPeriod.StartDate);
	Query.SetParameter("EndDate",					FilterPeriod.EndDate);
	Query.SetParameter("ScheduleStatus",					InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("OrderReferences",				OrderReferences.UnloadValues());
	Query.SetParameter("PlannedStagesOfProduction",	ProductionManagementCached.TheProductionScheduleIsUsed());
	Query.SetParameter("DynamicStructure",			Parameters.DynamicStructure);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		RowData = References.Add();
		FillPropertyValues(RowData, Selection);
		
		SpecificationString =
			ProductDataManagementClientServer.PresentationStage(
				Selection.BillOfMaterialsPresentation,
				Selection.StagePresentation,
				Selection.MultiStageProductionProcess);
		
		If Not ValueIsFilled(SpecificationString) Then
			SpecificationString = NStr("vi = 'không có bảng kê chi tiết';
										|ru = 'без спецификации';
										|en = 'without bill of materials'; fa = 'without bill of materials';
										|it = 'senza specifica';
										|pl = 'bez specyfikacji';
										|tr = 'ürün reçetesiz'");
		EndIf;
		
		RowData.ReferenceOrderPresentation =
			StringFunctionsClientServer.SubstituteParametersToString(
				OrderTemplate_1,
				ObjectsPrefixesClientServer.NumberForPrinting(Selection.OrderNumber__, False, True),
				Format(Selection.Order_Date, "DLF=D"),
				SpecificationString);
		
	EndDo;
	
	References.Sort("Check Desc, Begin");
	
EndProcedure

#EndRegion
