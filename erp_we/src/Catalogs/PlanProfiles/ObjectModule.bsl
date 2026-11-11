#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If IsNew() And Not IsFolder
	 	And PlanType.IsEmpty() Then
		
		AvailableTypes = New Array;
		If GetFunctionalOption("UsePurchasePlanning") Then
			AvailableTypes.Add(Enums.TypesOfPlans.PurchasePlan);
		EndIf;
		If GetFunctionalOption("UsePlanningOfGoodsStock") Then
			AvailableTypes.Add(Enums.TypesOfPlans.PlanOfGoodsStock);
		EndIf;
		If GetFunctionalOption("UseSalesPlansByCategories") Then
			AvailableTypes.Add(Enums.TypesOfPlans.SalesPlanByCategories);
		EndIf;
		If GetFunctionalOption("UseSalesPlans") Then
			AvailableTypes.Add(Enums.TypesOfPlans.SalesPlan);
		EndIf;
		If GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
			AvailableTypes.Add(Enums.TypesOfPlans.AssemblyDisassemblyPlan);
		EndIf;
		If GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
			AvailableTypes.Add(Enums.TypesOfPlans.InventoryConsumptionPlan);
		EndIf;
		If GetFunctionalOption("UseProductionPlanning") Then
			AvailableTypes.Add(Enums.TypesOfPlans.ProductionPlan);
		EndIf;
		If FillingData <> Undefined 
			And FillingData.Property("PlanType") 
			And AvailableTypes.Find(FillingData.PlanType) <> Undefined Then
			PlanType = FillingData.PlanType;
		ElsIf AvailableTypes.Count() > 0 Then
			PlanType = AvailableTypes[0];
		EndIf;
		
	EndIf;
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionPlanView(FillingData);
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If Not IsFolder Then
	EndIf;
	
EndProcedure


Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsNew() Then
		
		If PlanningOfGoodsStock
			And IsFolder Then
			PlanningProcedure = 0;
		Else
			PlanningProcedure = GetNewSchedulingOrder(ThisObject.Owner);
		EndIf;
		
	ElsIf Not IsFolder Then
		
		CheckForMatchingPlanningTypes(Cancel);
		
		PlanningStageBeforeRecording = Common.ObjectAttributeValue(Ref, "Parent");
		If PlanningStageBeforeRecording <> ThisObject.Parent Then
			
			PlanningProcedure = GetNewSchedulingOrder(ThisObject.Owner);
			
		EndIf;
		
	EndIf;
	
	If IsFolder Then	
		Return;
	EndIf;
	
	If FillInUsingFormula Then
		FillInPartnerInTabularForm = False;
		FillInAgreementInTabularForm = False;
		FillInWarehouseInTabularForm = False;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses")
		And Not FillInByServiceData Then
		FillInWarehouse = True;
	EndIf;
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	If PlanType = Enums.TypesOfPlans.ProductionPlan Then
		FillInPartner = False;
		FillInPartnerInTabularForm = False;
		FillInTermsOfSales = False;
		FillInAgreementInTabularForm = False;
		FillInWarehouse = False;
		FillInWarehouseInTabularForm = False;
		FillInPaymentPlan = False;
	ElsIf PlanType = Enums.TypesOfPlans.SalesPlan And Not ToUseTermsOfSales Then
		FillInTermsOfSales = False;
		FillInAgreementInTabularForm = False;
	EndIf;
	If FillInPaymentPlan And (FillInPartnerInTabularForm Or FillInAgreementInTabularForm) Then
		FillInPaymentPlan = False;
	EndIf;
	If FillInStoreFormat
		And (FillInWarehouse 
		Or FillInWarehouseInTabularForm)
		And (PlanType = Enums.TypesOfPlans.SalesPlan 
		Or PlanType = Enums.TypesOfPlans.SalesPlanByCategories) Then
		FillInStoreFormat = False;
	EndIf; 
	If FillInStoreFormat And Not GetFunctionalOption("UseStoreFormats") Then
		FillInStoreFormat = False;
	EndIf; 
	If Not FillInPartner And Not FillInPartnerInTabularForm Then
		FillInTermsOfSales = False;
		FillInAgreementInTabularForm = False;
	ElsIf Not FillInPartner And FillInPartnerInTabularForm Then
		FillInTermsOfSales = False;
	EndIf;
	
	If FillInPaymentPlan 
		And (PlanType = Enums.TypesOfPlans.PurchasePlan 
		Or PlanType = Enums.TypesOfPlans.SalesPlan) Then
		
		Attributes = Common.ObjectAttributesValues(Owner, "CreatePurchasePlanByAmount, CreateSalesPlanByAmount");
		
		If PlanType = Enums.TypesOfPlans.PurchasePlan 
			And Not Attributes.CreatePurchasePlanByAmount
			Or PlanType = Enums.TypesOfPlans.SalesPlan 
			And Not Attributes.CreateSalesPlanByAmount Then
		
			FillInPaymentPlan = False;
		
		EndIf; 
		
	EndIf; 
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		If PlanningOfGoodsStock  Then
			Query = New Query;
			Query.Text = 
			"SELECT
			|	PlanProfiles.Ref AS Ref
			|FROM
			|	Catalog.PlanProfiles AS PlanProfiles
			|WHERE
			|	PlanProfiles.PlanningOfGoodsStock
			|	AND PlanProfiles.Owner = &Owner
			|	AND PlanProfiles.Ref <> &Ref
			|	AND NOT PlanProfiles.DeletionMark
			|	AND PlanProfiles.IsFolder";
			Query.SetParameter("Owner", Owner);
			Query.SetParameter("Ref",Ref);
			
			If Query.Execute().Select().Next() Then
				
				MessageText = NStr("vi = 'Giai đoạn lập kế hoạch số dư chỉ có thể là 1.';
									|ru = 'Этап планирования остатков может быть только один.';
									|en = 'There can be only a single balance projection stage'; fa = 'There can be only a single balance projection stage';
									|it = 'La fase di pianificazione delle rimanenze può essere solo una.';
									|pl = 'Etap planowania pozostałości może być tylko jeden.';
									|tr = 'Sadece tek bir mal stoku planlama aşaması olabilir.'");
				CommonClientServer.MessageToUser(MessageText,,,, Cancel);
				
			EndIf;
		EndIf;
		
		If Not IsNew() Then
			Query = New Query;
			Query.Text = 
			"SELECT
			|	PlanProfiles.Ref AS Ref
			|FROM
			|	Catalog.PlanProfiles AS PlanProfiles
			|WHERE
			|	(PlanProfiles.PlanningOfGoodsStock <> &PlanningOfGoodsStock
			|	OR PlanProfiles.DemandPlanning <> &DemandPlanning)
			|	AND PlanProfiles.Parent = &Ref
			|	AND NOT PlanProfiles.DeletionMark";
			Query.SetParameter("DemandPlanning", DemandPlanning);
			Query.SetParameter("PlanningOfGoodsStock", PlanningOfGoodsStock);
			Query.SetParameter("Ref", Ref);
			
			If Query.Execute().Select().Next() Then
				
				MessageText = NStr("vi = 'Đối với giai đoạn lập kế hoạch, cần nhập kế hoạch với kiểu lập kế hoạch khác, không thể thay đổi kiểu này.';
									|ru = 'Для этапа планирования введены планы с другим типом планирования, смена типа невозможна.';
									|en = 'For the planning stage, the plans with a different planning type have been entered; you cannot change the type.'; fa = 'For the planning stage, the plans with a different planning type have been entered; you cannot change the type.';
									|it = 'Per la fase di pianificazione  sono introdotti i piani con altro tipo di pianificazione, la modifica del tipo non è possibile.';
									|pl = 'Dla etapu planowania zostały wprowadzone plany z innym typem planowania, zmiana typu nie jest możliwa.';
									|tr = 'Planlama aşaması için planların diğer planlama türleriyle tanıtımı, türü değiştirmek mümkün değildir.'");
				CommonClientServer.MessageToUser(MessageText,,,, Cancel);
				
			EndIf;
		EndIf;
		
		Return;
	Else
		CheckForMatchingPlanningTypes(Cancel);
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If PlanType <> Enums.TypesOfPlans.ProductionPlan Then
		NotCheckedAttributeArray.Add("ProductionProcessType");
	EndIf;
	
	If PlanType <> Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		NotCheckedAttributeArray.Add("BusinessOperation");
	EndIf;
	
	// Forecasting service.
	If Not FillInByServiceData Then
		NotCheckedAttributeArray.Add("ForecastQualityEstimationMetric");
		NotCheckedAttributeArray.Add("Periodicity");
		NotCheckedAttributeArray.Add("ForecastingStart");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillInSelectionPlanView(Val FillingData)
	
	If FillingData.Property("Owner") And FillingData.Property("PlanType") Then
		
		Scenario = FillingData.Owner;
		PlanType = FillingData.PlanType;
		
		If Not ValueIsFilled(Scenario) Or Not ValueIsFilled(PlanType) Then
			Return;
		EndIf;
		
		PlanProfile = Planning.GetDefaultPlanView(PlanType, Scenario);
		
		If ValueIsFilled(PlanProfile) Then
			AttributesNames = "FillInPartner, FillInTermsOfSales, FillInWarehouse, FillInBusinessUnit,
				|FillInPartnerInTabularForm, FillInAgreementInTabularForm, FillInWarehouseInTabularForm, FillInManager, FillInStoreFormat,
				|DisableEditingOfRule, FillInPaymentPlan, FillInUsingFormula, FillInCompany";
			Attributes = Common.ObjectAttributesValues(PlanProfile, AttributesNames);
			FillPropertyValues(ThisObject, Attributes);
		EndIf; 
		
	EndIf;
	
EndProcedure

Function GetNewSchedulingOrder(Scenario)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	Table.PlanningProcedure AS PlanningProcedure
	|FROM
	|	Catalog.PlanProfiles AS Table
	|WHERE
	|	Table.Owner = &Owner
	|
	|ORDER BY
	|	PlanningProcedure DESC");
	Query.SetParameter("Owner", Scenario);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return ?(Not ValueIsFilled(Selection.PlanningProcedure), 1, Selection.PlanningProcedure + 1);
	
EndFunction

Procedure CheckForMatchingPlanningTypes(Cancel)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PlanProfiles.Ref AS Ref
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	(PlanProfiles.PlanningOfGoodsStock <> &PlanningOfGoodsStock
	|	OR PlanProfiles.DemandPlanning <> &DemandPlanning)
	|	AND PlanProfiles.Ref = &Parent
	|	AND NOT PlanProfiles.DeletionMark";
	Query.SetParameter("DemandPlanning", DemandPlanning);
	Query.SetParameter("PlanningOfGoodsStock", PlanningOfGoodsStock);
	Query.SetParameter("Parent", Parent);
	
	If Query.Execute().Select().Next() Then
		
		MessageText = NStr("vi = 'Kiểu lập kế hoạch giai đoạn không tương ứng với kiểu lập kế hoạch dạng kế hoạch.';
							|ru = 'Тип планирования этапа не соответствует типу планирования вида плана.';
							|en = 'The stage planning type does not match the planning type of the plan.'; fa = 'The stage planning type does not match the planning type of the plan.';
							|it = 'Il tipo di pianificazione della fase non è conforme al tipo di pianificazione  del tipo di piano.';
							|pl = 'Typ planowania etapu nie odpowiada typowi planowania rodzaju planu.';
							|tr = 'Aşamanın planlama türü plan profiliyle eşleşmiyor.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
