
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Parameters.Property("OnDate") Then
		OnDate = Parameters.OnDate;
	EndIf;
	
	If Parameters.Property("DivisionsForWhichNoMetricValueIsEntered") Then
		ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered.LoadValues(Parameters.DivisionsForWhichNoMetricValueIsEntered);
	EndIf;
	
	If Parameters.Property("AllocationBase") Then
		Object.AllocationBase = Parameters.AllocationBase;
	EndIf;
	
	If GetFunctionalOption("ComplexAutomation")
		And Object.AssignRule = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots Then
		AssignRule = NStr("vi = 'Phân bổ các dạng chi phí theo sản phẩm xuất xưởng';
							|ru = 'Распределение статей расходов по выпускам продукции';
							|en = 'Allocate expense items by product releases'; fa = 'Allocate expense items by product releases';
							|it = 'Ripartizione delle voci di spesa secondo i prodotti';
							|pl = 'Przydział pozycji rozchodów wg wypuszczonej produkcji';
							|tr = 'İmal edilen ürün çıkışına ilişkin gider kalemlerinin dağıtımı'");
	Else
		AssignRule = TrimAll(Object.AssignRule);
	EndIf;
	
	ConfigureFormElementsByBatchAccountingVersion();
	
	FillSelectionLists();
	SetTargetVisibilityOnDivisions();
	SetTextAndVisibilityForDistributionDirection();
	EstablishDistributionBase();
	SetTextAndAvailabilityForDistributionBase();
	EstablishVisibilityOfSelectionByProductGroups();
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	SetFormHeader();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	SetVisibilityOnSelectionByProductGroups();
	SetSelectionLabelTestByProductGroups();
	SetVisibilityOfCalculationArticle();

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	SetFormHeader();
	FillSelectionLists();
	SetTextAndAvailabilityForDistributionBase();
	Notify("Write_CostAllocationRules");

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.FilterByProductsGroups.Clear();
	If UseProductGroupSelection 
		   And CurrentObject.AssignRule <> Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits Then
		For Each Item In FilterByProductsGroups Do 
			NewRow = CurrentObject.FilterByProductsGroups.Add();
			NewRow.ProductsGroup = Item.Value;
		EndDo;
	EndIf;
	CurrentObject.FilterByMaterials.Clear();
	If Object.AllocationBase = Enums.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials
		Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials
		Or Object.AllocationBase = Enums.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials Then
		For Each Item In FilterByMaterials Do 
			NewRow = CurrentObject.FilterByMaterials.Add();
			NewRow.Material = Item.Value;
		EndDo;
	EndIf;
	CurrentObject.FilterByActivityKind.Clear();
	If Object.AllocationBase = Enums.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds Then
		For Each Item In FilterByActivityKind Do 
			NewRow = CurrentObject.FilterByActivityKind.Add();
			NewRow.WorkKind = Item.Value;
		EndDo;
	EndIf;
	CurrentObject.FilterByBusinessUnits.Clear();

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits
		And Items.ManualDivisions.ChoiceList.FindByValue(AllocationBase) = Undefined
		And ((Object.Obsolete_ And Items.DivisionsAutomatically.ChoiceList.FindByValue(AllocationBase) = Undefined
			And Items.DivisionsMaterialsLabor.ChoiceList.FindByValue(AllocationBase) = Undefined)
			Or Not Object.Obsolete_) Then
		
		MessageText = NStr("vi = 'Loại chỉ tiêu không được chỉ định.';
							|ru = 'Не указан тип показателя.';
							|en = 'Indicator type is not specified.'; fa = 'Indicator type is not specified.';
							|it = 'Tipo di indicatore non specificato.';
							|pl = 'Nie wskazano typu nabywcy.';
							|tr = 'Gösterge türü belirtilmedi.'");
		CommonClientServer.MessageToUser(
			MessageText,
			, // Data key
			"AllocationBase",
			, // Data path
			Cancel);
			
	Else
		
		If (Object.AssignRule = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots
		And Items.StagesMaterialsAndLaborCosts.ChoiceList.FindByValue(AllocationBase) = Undefined
		And Items.StagesMaterialCosts.ChoiceList.FindByValue(AllocationBase) = Undefined
		And Items.StagesLaborCosts.ChoiceList.FindByValue(AllocationBase) = Undefined
		And Items.ProductionStages.ChoiceList.FindByValue(AllocationBase) = Undefined)
	
		Or
		(Object.AssignRule = Enums.AssignmentOfCostAllocationRules.MaterialsAndWorksCostAllocation
		And Items.MaterialsAndWorksMaterialCosts.ChoiceList.FindByValue(AllocationBase) = Undefined
		And Items.MaterialsAndWorksProducts_.ChoiceList.FindByValue(AllocationBase) = Undefined
		And Items.MaterialsAndWorksTheStandardOfConsumptionOfThisMaterial.ChoiceList.FindByValue(AllocationBase) = Undefined)
		Then
		
			MessageText = NStr("vi = 'Không có cơ sở phân bổ được chọn';
								|ru = 'Не выбрано ни одной базы распределения';
								|en = 'No allocation base is selected.'; fa = 'No allocation base is selected.';
								|it = 'Non è stata selezionata nemmeno una base di ripartizione';
								|pl = 'Nie wybrano żadnej podstawy przydziału';
								|tr = 'Herhangi bir tahsisat tabanı seçilmedi'");
			CommonClientServer.MessageToUser(
				MessageText,
				, // Data key
				"AllocationBase",
				, // Data path
				Cancel);
			
		EndIf;
			
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LabelFilterByProductGroupsClick(Item)
	
	StandardProcessing = False;
	FilterParameters = New Structure();
	FilterParameters.Insert("ArrayOfProductGroups", FilterByProductsGroups.UnloadValues());
	SelectionResult_ = Undefined;

	OpenForm("Catalog.CostAllocationRules.Form.FilterForm",
			FilterParameters,
			ThisForm,,,, 
			New CallbackDescription("LabelSelectionClickFinish", ThisObject, "FilterByProductsGroups"), 
			FormWindowOpeningMode.LockOwnerWindow);
			
EndProcedure

&AtClient
Procedure UseProductGroupSelectionOnChange(Item)
	
	SetVisibilityOnSelectionByProductGroups();
	Modified = True;
	
EndProcedure

&AtClient
Procedure LabelAllocationBaseFilterClick()
	
	StandardProcessing = False;
	FilterParameters = New Structure();
	AdditionalSelectionParameter = "";
	If AllocationBase = "QuantityOfSpecifiedMaterials"
		Or AllocationBase = "WeightOfSpecifiedMaterials"
		Or AllocationBase = "VolumeOfSpecifiedMaterials" Then
		FilterParameters.Insert("ArrayOfMaterials", FilterByMaterials.UnloadValues());
		AdditionalSelectionParameter = "FilterByMaterials";
	ElsIf AllocationBase = "NumberOfWorksOfSpecifiedKinds" Then
		FilterParameters.Insert("ArrayOfTypesOfWork", FilterByActivityKind.UnloadValues());
		AdditionalSelectionParameter = "FilterByActivityKind";
	EndIf;
	SelectionResult_ = Undefined;

	OpenForm("Catalog.CostAllocationRules.Form.FilterForm",
			FilterParameters,
			ThisForm,,,, 
			New CallbackDescription("LabelSelectionClickFinish", ThisObject, AdditionalSelectionParameter), 
			FormWindowOpeningMode.LockOwnerWindow);
			
EndProcedure

&AtClient
Procedure LabelSelectionDirectionClick(Item)
	
	StandardProcessing = False;
	FilterParameters = New Structure();
	FilterParameters.Insert("ArrayOfDivisions", FilterByBusinessUnits.UnloadValues());
	AdditionalSelectionParameter = "FilterByBusinessUnits";
	SelectionResult_ = Undefined;

	OpenForm("Catalog.CostAllocationRules.Form.FilterForm",
			FilterParameters,
			ThisForm,,,, 
			New CallbackDescription("LabelSelectionClickFinish", ThisObject, AdditionalSelectionParameter), 
			FormWindowOpeningMode.LockOwnerWindow);
			
EndProcedure

&AtClient
Procedure StagesMaterialsAndLaborCostsOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure StagesMaterialCostsOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure StagesLaborCostsOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure ProductionStagesOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure ManualDivisionsOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure DivisionsAutomaticallyOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksMaterialCostsOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksProducts_OnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksTheStandardOfConsumptionOfThisMaterialOnChange(Item)
	
	SetTextAndAvailabilityForDistributionBase();
	
EndProcedure

&AtClient
Procedure TheInscriptionStepsToSpecifyMaterialsClick(Item)
	
	LabelAllocationBaseFilterClick();
	
EndProcedure

&AtClient
Procedure TheInscriptionStepsToSpecifyTheTypesOfWorkClick(Item)
	
	LabelAllocationBaseFilterClick();
	
EndProcedure

&AtClient
Procedure TheInscriptionOfUnitValuesClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("Factor", Object.Ref);
	FormParameters.Insert("OnlyValues");
	
	If Not FilterByBusinessUnits.Count() = 0 Then
		FormParameters.Insert("Departments",FilterByBusinessUnits);
	EndIf;
	
	OpenForm("Catalog.CostAllocationRules.Form.ListFormManually",
						FormParameters,
						ThisForm,
						,,,,
						FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure LabelMaterialsAndWorksSpecifyMaterialsClick(Item)
	
	LabelAllocationBaseFilterClick();
	
EndProcedure

&AtClient
Procedure LabelMaterialsAndWorksSpecifyTheTypesOfWorkClick(Item)
	
	LabelAllocationBaseFilterClick();
	
EndProcedure

&AtClient
Procedure AllocationDirectionOnChange(Item)
	
	SetTextAndVisibilityForDistributionDirection();
	
EndProcedure

&AtClient
Procedure AllocationDirectionClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSelectionLists()
	
	FilterByProductsGroups.LoadValues(Object.FilterByProductsGroups.Unload(, "ProductsGroup").UnloadColumn("ProductsGroup"));
	UseProductGroupSelection = (FilterByProductsGroups.Count() > 0);
	FilterByActivityKind.LoadValues(Object.FilterByActivityKind.Unload(, "WorkKind").UnloadColumn("WorkKind"));
	FilterByMaterials.LoadValues(Object.FilterByMaterials.Unload(, "Material").UnloadColumn("Material"));
	
EndProcedure

&AtClient
Procedure SetVisibilityOnSelectionByProductGroups()
	
	Items.LabelFilterByProductGroups.Visible = UseProductGroupSelection;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfCalculationArticle()
	
	Items.ProductCostElement.Visible = (Object.AssignRule = PredefinedValue("Enum.AssignmentOfCostAllocationRules.MaterialsAndWorksCostAllocation")
							Or Object.AssignRule = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots"));
	
EndProcedure

&AtClient
Procedure SetSelectionLabelTestByProductGroups()
	
	LabelText = "";
	For Each Item In FilterByProductsGroups Do 
		LabelText = LabelText + ?(LabelText = "", "", "; ") + TrimAll(Item.Value);
	EndDo;
	If LabelText = "" Then
		LabelText = NStr("vi = 'Cho biết nhóm sản phẩm (loại)';
						|ru = 'Указать группы (виды) продукции';
						|en = 'Specify groups (kinds) of manufactured products'; fa = 'Specify groups (kinds) of manufactured products';
						|it = 'Indicare i gruppi (tipi) di produzione';
						|pl = 'Określ grupy (rodzaje) produkcji';
						|tr = 'İmal edilen ürün grubunu (türünü) belirt'");
	EndIf;
	Items.LabelFilterByProductGroups.Title = LabelText;
	
EndProcedure

&AtClient
Procedure LabelSelectionClickFinish(Result, AdditionalParameters) Export
	
	SelectionResult_ = Result;
	If TypeOf(SelectionResult_) = Type("Array") Then
		If AdditionalParameters = "FilterByProductsGroups" Then
			FilterByProductsGroups.LoadValues(SelectionResult_);
			SetSelectionLabelTestByProductGroups();
			Modified = True;
		ElsIf AdditionalParameters = "FilterByMaterials" Then
			FilterByMaterials.LoadValues(SelectionResult_);
			SetTextAndAvailabilityForDistributionBase();
			Modified = True;
		ElsIf AdditionalParameters = "FilterByActivityKind" Then
			FilterByActivityKind.LoadValues(SelectionResult_);
			SetTextAndAvailabilityForDistributionBase();
			Modified = True;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure SetSelectionLabelTestByMaterials()
	
	If FilterByMaterials.Count() = 0 Then
		LabelText = NStr("vi = 'Chỉ định nguyên vật liệu';
						|ru = 'Указать материалы';
						|en = 'Specify materials'; fa = 'تعیین مواد';
						|it = 'Indicare i materiali';
						|pl = 'Określ materiały';
						|tr = 'Malzemeleri belirt'");
	Else
		
		Template = NStr("vi = 'Đã chỉ ra nguyên vật liệu (%1)';
						|ru = 'Материалы указаны (%1)';
						|en = 'Materials specified (%1)'; fa = 'Materials specified (%1)';
						|it = 'I materiali sono indicati (%1)';
						|pl = 'Wyznaczono materiały (%1)';
						|tr = 'Malzemeler belirtildi (%1)'");
		LabelText = StrTemplate(Template, Format(FilterByMaterials.Count(), "NZ=0; NG=0;"));
		
	EndIf;
	
	Items.TheInscriptionStepsToSpecifyMaterials.Title = LabelText;
	Items.LabelMaterialsAndWorksSpecifyMaterials.Title = LabelText;
	
EndProcedure

&AtServer
Procedure SetSelectionLabelTestByTypeOfWork()
	
	If FilterByActivityKind.Count() = 0 Then
		LabelText = NStr("vi = 'Chỉ định loại công việc';
						|ru = 'Указать виды работ';
						|en = 'Specify activity kinds'; fa = 'تعیین انواع فعالیت';
						|it = 'Indicare i tipi dei lavori';
						|pl = 'Określ rodzaje prac';
						|tr = 'Etkinlik türlerini belirt'");
	Else
		
		Template = NStr("vi = 'Đã chỉ ra dạng công việc (%1)';
						|ru = 'Виды работ указаны (%1)';
						|en = 'Activity kinds specified (%1)'; fa = 'Activity kinds specified (%1)';
						|it = 'I tipi di lavori sono indicati (%1)';
						|pl = 'Wyznaczono rodzaje prac (%1)';
						|tr = 'Etkinlik türleri belirtildi (%1)'");
		LabelText = StrTemplate(Template, Format(FilterByActivityKind.Count(), "NZ=0; NG=0;"));
		
	EndIf;
	Items.TheInscriptionStepsToSpecifyTheTypesOfWork.Title = LabelText;
	Items.LabelMaterialsAndWorksSpecifyTheTypesOfWork.Title = LabelText;
	
EndProcedure

&AtServer
Procedure SetTextAndAvailabilityForDistributionBase()

	Items.InformationGroup.Visible = False;
	
	If AllocationBase = "QuantityOfSpecifiedMaterials"
		Or AllocationBase = "WeightOfSpecifiedMaterials"
		Or AllocationBase = "VolumeOfSpecifiedMaterials" Then
		Items.TheInscriptionStepsToSpecifyMaterials.Enabled = True;
		Items.LabelMaterialsAndWorksSpecifyMaterials.Enabled = True;
		Items.TheInscriptionStepsToSpecifyTheTypesOfWork.Enabled = False;
		Items.LabelMaterialsAndWorksSpecifyTheTypesOfWork.Enabled = False;
		Items.TheInscriptionOfUnitValues.Enabled = False;
		
		If FilterByMaterials.Count() > 0 Then
			
			WarningText = CheckCorrectnessOfSpecifiedMaterials();
			Items.InformationGroup.Visible = Not IsBlankString(WarningText);
			
		EndIf;
		
	ElsIf AllocationBase = "NumberOfWorksOfSpecifiedKinds" Then
		Items.TheInscriptionStepsToSpecifyTheTypesOfWork.Enabled = True;
		Items.LabelMaterialsAndWorksSpecifyTheTypesOfWork.Enabled = True;
		Items.TheInscriptionStepsToSpecifyMaterials.Enabled = False;
		Items.LabelMaterialsAndWorksSpecifyMaterials.Enabled = False;
		Items.TheInscriptionOfUnitValues.Enabled = False;
	ElsIf AllocationBase = "VariableEnteredManuallyOnMonthlyBasis" Or AllocationBase = "ConstantEnteredManuallyOnDemand" Then
		Items.TheInscriptionOfUnitValues.Enabled = True;
		Items.TheInscriptionStepsToSpecifyTheTypesOfWork.Enabled = False;
		Items.LabelMaterialsAndWorksSpecifyTheTypesOfWork.Enabled = False;
		Items.TheInscriptionStepsToSpecifyMaterials.Enabled = False;
		Items.LabelMaterialsAndWorksSpecifyMaterials.Enabled = False;
	Else
		Items.TheInscriptionStepsToSpecifyTheTypesOfWork.Enabled = False;
		Items.LabelMaterialsAndWorksSpecifyTheTypesOfWork.Enabled = False;
		Items.TheInscriptionStepsToSpecifyMaterials.Enabled = False;
		Items.LabelMaterialsAndWorksSpecifyMaterials.Enabled = False;
		Items.TheInscriptionOfUnitValues.Enabled = False;
	EndIf;
	If ValueIsFilled(AllocationBase) Then
		Object.AllocationBase = Enums.TypesOfCostAllocatingBase[AllocationBase];
	EndIf;

	SetSelectionLabelTestByMaterials();
	SetSelectionLabelTestByTypeOfWork();
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfSelectionByProductGroups()
	
	Items.GroupSelectionByProductType.Visible = GetFunctionalOption("AnalyticalAccountingByProductsGroups")
		And Object.AssignRule <> Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits;
	
EndProcedure

&AtServer
Procedure EstablishDistributionBase()
	
	If Object.AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits Then
		Items.PagesAllocationBase.CurrentPage = Items.PageByDepartments;
		If Not ValueIsFilled(Object.Ref) And Not ValueIsFilled(Object.AllocationBase) Then
			Object.AllocationBase = Enums.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts;
		EndIf;
	ElsIf Object.AssignRule = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots Then
		Items.PagesAllocationBase.CurrentPage = Items.PageByStages;
		If Not ValueIsFilled(Object.Ref) And Not ValueIsFilled(Object.AllocationBase) Then
			Object.AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsQuantity;
		EndIf;
	Else
		Items.PagesAllocationBase.CurrentPage = Items.PageOfMaterialsAndWorks;
		If Not ValueIsFilled(Object.Ref) And Not ValueIsFilled(Object.AllocationBase) Then
			Object.AllocationBase = Enums.TypesOfCostAllocatingBase.ProductsQuantity;
		EndIf;
	EndIf;
	
	AllocationBase = XMLString(Object.AllocationBase);
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsByBatchAccountingVersion()
	
	If Not CalculationOfCostCached.BatchAccountingVersion22() Then
		Items.DirectCostGroup.Visible = False;
		Items.DivisionsMaterialsLabor.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Function CheckCorrectnessOfSpecifiedMaterials()
	
	WarningText = "";
	If AllocationBase = "QuantityOfSpecifiedMaterials" Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	Products.UnitOfMeasure.MeasuredValueType AS MeasuredValueType,
			|	COUNT(Products.Ref) AS Count
			|FROM
			|	Catalog.Products AS Products
			|WHERE
			|	Products.Ref IN(&DataArray)
			|
			|GROUP BY
			|	Products.UnitOfMeasure.MeasuredValueType";
		
		Query.SetParameter("DataArray", FilterByMaterials.UnloadValues());
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Count() > 1 Then
			
			WarningText = NStr("vi = 'Có lẽ các chứng từ được chỉ định không chính xác. Vật liệu được lưu trữ trong các giá trị đo khác nhau:';
								|ru = 'Возможно материалы указаны некорректно. Материалы хранятся в разных измеряемых величинах:';
								|en = 'Materials may be specified incorrectly. Materials are stored in different measured values:'; fa = 'Materials may be specified incorrectly. Materials are stored in different measured values:';
								|it = 'È possibile che i materiali siano stati indicati incorrettamente. I materiali sono memorizzati in diversi valori misurati:';
								|pl = 'Możliwe, że materiały zostały wskazane nieprawidłowo. Materiały są przechowywane w różnych wielkościach mierzalnych:';
								|tr = 'Malzemeler doğru belirtilmemiş olabilir. Malzemeler farklı ölçülebilir büyüklüklerde saklanmaktadır:'") + " ";
			
			While Selection.Next() Do
				WarningText = WarningText + Selection.MeasuredValueType + "(" + Format(Selection.Count, "NG=0") + "), ";
			EndDo;
			
			WarningText = Left(WarningText, StrLen(WarningText) - 2);
			
		EndIf;
		
	Else
		
		BasePresentation = "";
		MeasuredValueType = Enums.TypesOfMeasuredValues.EmptyRef();
		If AllocationBase = "VolumeOfSpecifiedMaterials" Then
			
			MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3;
			BasePresentation = NStr("vi = 'khối lượng';
									|ru = 'объем';
									|en = 'volume'; fa = 'volume';
									|it = 'volume';
									|pl = 'objętość';
									|tr = 'hacim'");
			
		ElsIf AllocationBase = "WeightOfSpecifiedMaterials" Then
			
			MeasuredValueType = Enums.TypesOfMeasuredValues.Weight;
			BasePresentation = NStr("vi = 'trọng lượng';
									|ru = 'вес';
									|en = 'weight'; fa = 'weight';
									|it = 'peso';
									|pl = 'waga';
									|tr = 'ağırlık'");
			
		EndIf;
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	COUNT(DISTINCT AllProducts.Ref) AS QuantityOfMaterials
			|FROM
			|	Catalog.Products AS AllProducts
			|		LEFT JOIN Catalog.Products AS Products
			|		ON (Products.UnitOfMeasure.MeasuredValueType = &MeasuredValueType
			|				OR &VolumeM3
			|					AND Products.VolumeUse
			|				OR &Weight
			|					AND Products.WeightUse)
			|			AND AllProducts.Ref = Products.Ref
			|WHERE
			|	AllProducts.Ref IN(&DataArray)
			|	AND Products.Ref IS NULL";
		
		Query.SetParameter("DataArray", FilterByMaterials.UnloadValues());
		Query.SetParameter("MeasuredValueType", MeasuredValueType);
		Query.SetParameter("VolumeM3", MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3);
		Query.SetParameter("Weight", MeasuredValueType = Enums.TypesOfMeasuredValues.Weight);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		WarningTemplate = NStr("vi = 'Không thể có được hệ số chuyển đổi cho vật liệu (1%) là 2%.';
								|ru = 'Невозможно получить коэффициент пересчета для материалов (1%) в 2%.';
								|en = 'Cannot receive a ratio for materials (1%) conversion to 2%.'; fa = 'Cannot receive a ratio for materials (1%) conversion to 2%.';
								|it = 'Non è possibile ottenere un fattore di conversione per i materiali (1%) al 2%.';
								|pl = 'Nie można uzyskać współczynnika przeliczenia dla materiałów (1%) w 2%.';
								|tr = '2% içinde (1%) malzemeleri için dönüştürme oranı almak mümkün değildir.'");
		
		While Selection.Next() Do
			If Selection.QuantityOfMaterials > 0 Then
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningTemplate, 
					Format(Selection.QuantityOfMaterials, "NG=0"),
					BasePresentation);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return WarningText;
	
EndFunction

&AtServer
Procedure SetFormHeader()
	
	If Object.AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits Then
		
		AutoTitle = False;
		Items.AssignRule.Visible = False;
		
		TitleText = NStr("vi = '%1 (%2)';
						|ru = '%1 (%2)';
						|en = '%1 (%2)'; fa = '%1 (%2)';
						|it = '%1 (%2)';
						|pl = '%1 (%2)';
						|tr = '%1 (%2)'");
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(TitleText,
				Object.Description,
				NStr("vi = 'Chỉ tiêu';
					|ru = 'Показатель';
					|en = 'Indicator'; fa = 'شاخص';
					|it = 'Indicatore';
					|pl = 'Wskaźnik';
					|tr = 'Gösterge'"));
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(TitleText,
				NStr("vi = 'Chỉ tiêu';
					|ru = 'Показатель';
					|en = 'Indicator'; fa = 'شاخص';
					|it = 'Indicatore';
					|pl = 'Wskaźnik';
					|tr = 'Gösterge'"),
				NStr("vi = 'tạo';
					|ru = 'создание';
					|en = 'create'; fa = 'ایجاد';
					|it = 'creazione';
					|pl = 'tworzenie';
					|tr = 'oluşturma'"));
		EndIf;
			
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionLabelTestByDivisions()
	
	LabelText = "";
	For Each Item In FilterByBusinessUnits Do 
		LabelText = LabelText + ?(LabelText = "", "", "; ") + TrimAll(Item.Value);
	EndDo;
	If LabelText = "" Then
		LabelText = NStr("vi = 'Chỉ định đơn vị';
						|ru = 'Указать подразделения';
						|en = 'Specify business units'; fa = 'تعیین واحدهای تجاری';
						|it = 'Indicare i reparti';
						|pl = 'Wskaż działy';
						|tr = 'Departmanına belirt'");
	EndIf;
	Items.LabelSelectionDirection.Title = LabelText;
	
EndProcedure

&AtServer
Procedure SetTextAndVisibilityForDistributionDirection()

	SetSelectionLabelTestByDivisions();
	
EndProcedure

&AtServer
Procedure SetTargetVisibilityOnDivisions()
	
	Items.GroupDirection.Visible = 
		Object.AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits
		And Object.Obsolete_;
		
	Items.DivisionsColumn2.Visible = Object.Obsolete_;
	
EndProcedure

#EndRegion
