
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	FillInFormDetailsByParameters();
	SetFormHeader();
	ConfigureFormElementsByParameters();
	
	If Parameters.ReadOnly Then
		
		ItemArray = New Array;
		ItemArray.Add(Items.BillOfMaterials.Name);
		ItemArray.Add(Items.KitSpecification.Name);
		ItemArray.Add(Items.BillOfMaterialsRM.Name);
		ItemArray.Add(Items.PlanNotEarlierThan.Name);
		ItemArray.Add(Items.ReleaseStage.Name);
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ChoiceButton",   False);
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ClearButton",  False);
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "OpenButton", True);
		
	EndIf;
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(New Structure(), Catalogs.BillsOfMaterials);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.BillOfMaterials,        BOMSelectionParameters.Assembly);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.KitSpecification,  BOMSelectionParameters.Assembly);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.BillOfMaterialsRM, BOMSelectionParameters.Repair);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	If MethodOfReceivingMaterial <> Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
		
		NotCheckedAttributeArray.Add("ReleaseStage");
		
	EndIf;
	
	If Not (MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
		And (ProductionIsUsed21 Or DynamicStructureOfProductionOrders))
			And Not (MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.Provide
				And MarkCompositionAccordingToSpecification) Then
		
		NotCheckedAttributeArray.Add("BillOfMaterials");
		
	EndIf;

	If Not MarkRepairAccordingToSpecification Then
		
		NotCheckedAttributeArray.Add("BillOfMaterialsRM");
		
	EndIf;
	
	If Not MarkPlanNotEarlierThan Then
		
		NotCheckedAttributeArray.Add("PlanNotEarlierThan");
		
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ChoiceSource) = Type("ClientApplicationForm")
		And (ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm") Then
			
		Mode = ValueSelected.Mode;
		
		If Mode = "ReleaseStage" Then
			ReleaseStage = ValueSelected.Stage;
			ReleaseStagePresentation = ValueSelected.StagePresentation;
			AddIntermediateReleaseOnSelection = ValueSelected.AddIntermediateReleaseOnSelection
		Else
			PlanNotEarlierThan = ValueSelected.Stage;
			PlanNotEarlierThanPresentation = ValueSelected.StagePresentation;
		EndIf;
		
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MethodForGettingTheMaterialWhenChanging(Item)
	WhenChangingMethodOfObtainingMaterial();
	Return; // empty handler

EndProcedure

&AtClient
Procedure ReleaseStageClearing(Item, StandardProcessing)
	
	ReleaseStage = Undefined;
	ReleaseStagePresentation = "";
	
EndProcedure

&AtClient
Procedure ReleaseStageOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	StageOpening(ReleaseStage);
	
EndProcedure

&AtClient
Procedure ReleaseStageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Mode",           "ReleaseStage");
	FormParameters.Insert("CurrentRef",   ReleaseStage);
	FormParameters.Insert("Products",    Products);
	FormParameters.Insert("Characteristic",  Characteristic);
	FormParameters.Insert("AddressInStorage", AddressSemiFinishedProducts);
	
	OpenForm("Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure PlanNotEarlierThanClearing(Item, StandardProcessing)
	
	PlanNotEarlierThan = Undefined;
	PlanNotEarlierThanPresentation = "";
	
EndProcedure

&AtClient
Procedure PlanNotEarlierThanOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	StageOpening(PlanNotEarlierThan);
	
EndProcedure

&AtClient
Procedure PlanNotEarlierThanStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Mode",           "Stage");
	FormParameters.Insert("CurrentRef",   PlanNotEarlierThan);
	FormParameters.Insert("AddressInStorage", AddressSemiFinishedProducts);
	
	OpenForm("Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure MarkCompositionAccordingToSpecificationOnChange(Item)
	
	BillOfMaterials = Undefined;
	ConfigureDependentFormElements(ThisObject);
EndProcedure

&AtClient
Procedure KitSpecificationOnChange(Item)
	ConfigureDependentFormElements(ThisObject);
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	ClearMessages();
	
	If CheckFilling() Then
		
		If Modified Then
			Modified = False;
			NotifyChoice(SelectionValue());
		Else
			Close();
		EndIf;
		
	EndIf;
	Return; // empty handler

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInFormDetailsByParameters()
	
	SubsystemSettingsProduction = ProductionServerCached.SubsystemSettingsProduction();
	FillPropertyValues(ThisForm, SubsystemSettingsProduction);
	
	Stage = Parameters.Stage;
	Owner = Parameters.Owner;
	
	Products             = Parameters.Products;
	Characteristic           = Parameters.Characteristic;
	ThisIsTheFirstStep            = Parameters.ThisIsTheFirstStep;
	ThisIsMaterialSet         = Parameters.ThisIsMaterialSet;
	ThisIsTechnologicalSet  = Parameters.ThisIsTechnologicalSet;
	MethodOfReceivingMaterial = Parameters.MethodOfReceivingMaterial;
	
	If MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials Then
		
		BillOfMaterials = Parameters.SourceOfSemiFinishedProduct;
		
	ElsIf MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
		
		ReleaseStage = Parameters.SourceOfSemiFinishedProduct;
		ReleaseStagePresentation = Parameters.SourceOfSemiFinishedProductPresentation;
		
	ElsIf MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.Provide
		And ThisIsMaterialSet Then
		
		BillOfMaterials = Parameters.SourceOfSemiFinishedProduct;
		MarkCompositionAccordingToSpecification = ValueIsFilled(BillOfMaterials);
		
	EndIf;
	
	If DynamicStructureOfProductionOrders Then // reset outdated settings
		PlanNotEarlierThan = Undefined;
		PlanNotEarlierThanPresentation = "";
	Else
		PlanNotEarlierThan = Parameters.PlanNotEarlierThan;
		PlanNotEarlierThanPresentation = Parameters.PlanNotEarlierThanPresentation;
	EndIf;
	
	If MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
		And ValueIsFilled(PlanNotEarlierThan) Then
		
		MarkPlanNotEarlierThan = True;
	Else
		
		MarkPlanNotEarlierThan = False;
	EndIf;
	
	If Parameters.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
		
		If MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
			And ValueIsFilled(Parameters.BillOfMaterialsRM) Then
			
			MarkRepairAccordingToSpecification = True;
		Else
			
			MarkRepairAccordingToSpecification = False;
		EndIf;
		
		BillOfMaterialsRM = Parameters.BillOfMaterialsRM;
		
	EndIf;
	
	AddressSemiFinishedProducts = Parameters.AddressSemiFinishedProducts;
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If ValueIsFilled(Products) Then
	
		TextProducts = StrTemplate(NStr("vi = 'Mặt hàng: %1';
										|ru = 'Номенклатура: %1';
										|en = 'Item: %1'; fa = 'Item: %1';
										|it = 'Articolo: %1';
										|pl = 'Towary: %1';
										|tr = 'Öğe: %1'"), Products);
		
		If ValueIsFilled(Characteristic) Then
			
			TextProducts = TextProducts + ", " + StrTemplate(NStr("vi = 'Đặc tính: %1';
																	|ru = 'Характеристика: %1';
																	|en = 'Item variant: %1'; fa = 'Item variant: %1';
																	|it = 'Caratteristica: %1';
																	|pl = 'Charakterystyka: %1';
																	|tr = 'Varyant: %1'"), Characteristic);
			
		EndIf;
		
		AutoTitle = False;
		Title = StrTemplate(NStr("vi = 'Phương thức nhận (%1)';
								|ru = 'Способ получения (%1)';
								|en = 'Receipt method (%1)'; fa = 'Receipt method (%1)';
								|it = 'Metodo di ricezione (%1)';
								|pl = 'Sposób odbioru (%1)';
								|tr = 'Alma yöntemi (%1)'"), TextProducts);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsByParameters()
	
	If DynamicStructureOfProductionOrders Or ProductionIsUsed21 Then
		Items.BillOfMaterials.AutoMarkIncomplete = True;
		Items.BillOfMaterials.InputHint = "";
	Else
		Items.BillOfMaterials.AutoMarkIncomplete = False;
		Items.BillOfMaterials.InputHint = NStr("vi = '<được chọn tự động>';
												|ru = '<подбирается автоматически>';
												|en = '<picked automatically>'; fa = '<picked automatically>';
												|it = '<viene selezionato automaticamente>';
												|pl = '<wybierane automatycznie>';
												|tr = '<otomatik olarak seçilir>'");
	EndIf;
	
	// Provide
	Items.GroupCompositionAccordingToSpecification.Visible = ThisIsMaterialSet
		And (ProductDataManagementCached.ItIsAvailableToStoreCompositionOfSetInSpecifications()
			Or ValueIsFilled(BillOfMaterials));
	
	// Produced at the stage
	Items.TheGroupIsMadeAtTheStage.Visible = Not ThisIsTechnologicalSet;
	Items.TheMethodIsPerformedAtTheStage.Enabled = (Parameters.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData)
		And Not ThisIsTheFirstStep
		And Not ThisIsMaterialSet;
	Items.AGroupOfRepairSpecifications.Visible = (Parameters.ProductionProcessType = Enums.ProductionProcessTypes.Repair);
	
	// Produced according to the specification
	Items.TheMethodIsMadeAccordingToTheSpecification.Enabled = (Parameters.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
			Or Parameters.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty)
		And Not ThisIsMaterialSet;
	Items.GroupPlanNotEarlier.Visible = Not ProductionIsUsed21 And Not ThisIsMaterialSet And Not ThisIsTechnologicalSet And Not DynamicStructureOfProductionOrders;
	
	SetKeyToSaveWindowPosition();
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form)
	
	Items = Form.Items;
	
	Items.ReleaseStage.Visible  = (Form.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage"));
	Items.BillOfMaterials.Visible = (Form.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials"));
	
	Items.AGroupOfRepairSpecifications.Enabled = (Form.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage"));
	Items.GroupPlanNotEarlier.Enabled = (Form.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials"));
	
	Items.BillOfMaterialsRM.Visible = Form.MarkRepairAccordingToSpecification;
	Items.PlanNotEarlierThan.Visible = Form.MarkPlanNotEarlierThan;
	
	Items.KitSpecification.MarkIncomplete = Form.MarkCompositionAccordingToSpecification And Not ValueIsFilled(Form.BillOfMaterials);
	Items.KitSpecification.ReadOnly = Not Form.MarkCompositionAccordingToSpecification;
	Items.KitSpecification.InputHint = ?(Form.MarkCompositionAccordingToSpecification, "", NStr("vi = '<bảng kê chi tiết thành phần được chọn tự động>';
																								|ru = '<спецификация состава подбирается автоматически>';
																								|en = '<bill of materials of the content is picked automatically>'; fa = '<bill of materials of the content is picked automatically>';
																								|it = '<specifica della composizione selezionata automaticamente>';
																								|pl = '<specyfikacja składu jest dobierana automatycznie>';
																								|tr = '<içerik ürün reçetesi otomatik olarak seçilir>'"));
	
EndProcedure

&AtClient
Function SelectionValue()
	
	Result = New Structure;
	
	Result.Insert("MethodOfReceivingMaterial", MethodOfReceivingMaterial);
	Result.Insert("SourceOfSemiFinishedProduct", SourceOfSemiFinishedProduct());
	
	If MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials")
		And MarkPlanNotEarlierThan Then
		
		Result.Insert("PlanNotEarlierThan", PlanNotEarlierThan);
	Else
		
		Result.Insert("PlanNotEarlierThan", PredefinedValue("Catalog.ProductionStages.EmptyRef"));
	EndIf;
	
	If MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage") Then
		
		If MarkRepairAccordingToSpecification Then
			Result.Insert("BillOfMaterialsRM", BillOfMaterialsRM);
		Else
			Result.Insert("BillOfMaterialsRM", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
		EndIf;
		
		If AddIntermediateReleaseOnSelection Then
			Result.Insert("AddIntermediateReleaseOnSelection", AddIntermediateReleaseOnSelection);
		EndIf;
		
	EndIf;
	
	Result.Insert("ProducedInProcess", ProductDataManagementClientServer.SemiFinishedProductProducedInProcess(Result));
	
	Return Result;
	
EndFunction

&AtClient
Function SourceOfSemiFinishedProduct()
	
	If MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage") Then
		Result = ReleaseStage;
	Else
		Result = BillOfMaterials;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure WhenChangingMethodOfObtainingMaterial()

	If MethodOfReceivingMaterial <> Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials Then
		
		BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
		MarkPlanNotEarlierThan = False;
		
	EndIf;

	If MethodOfReceivingMaterial <> Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
		
		ReleaseStage = Catalogs.ProductionStages.EmptyRef();
		ReleaseStagePresentation = "";
		MarkRepairAccordingToSpecification = False;
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtServer
Procedure SetKeyToSaveWindowPosition()
	
	ArrayOfFeatures = New Array;
	ArrayOfFeatures.Add(ProductionIsUsed22);
	ArrayOfFeatures.Add(ThisIsTechnologicalSet);
	ArrayOfFeatures.Add(ThisIsMaterialSet);
	
	WindowOptionsKey = StrTemplate("%1_%2", ThisObject.FormName, StrConcat(ArrayOfFeatures));
	
EndProcedure

&AtClient
Procedure StageOpening(StageLink)
	
	If ThereIsPossibilityOfOpeningStage(ReleaseStage) Then
		FormParameters = New Structure("Key,ReadOnly", StageLink, True);
		OpenForm("Catalog.ProductionStages.ObjectForm", FormParameters);
	Else
		ShowMessageBox(, NStr("vi = 'Chỉ có thể mở phần tử sau khi ghi lại.';
								|ru = 'Открыть элемент можно только после его записи.';
								|en = 'Element can be opened after it has been saved.'; fa = 'Element can be opened after it has been saved.';
								|it = 'L''elemento può essere aperto previo salvataggio.';
								|pl = 'Otwórz element można tylko po jego zapisaniu.';
								|tr = 'Öğeyi sadece kaydettikten sonra açabilirsiniz.'"));
	EndIf;
	
EndProcedure

&AtServer
Function ThereIsPossibilityOfOpeningStage(StageLink)
	
	Return ValueIsFilled(Common.ObjectAttributeValue(StageLink, "Ref"));
	
EndFunction

#EndRegion