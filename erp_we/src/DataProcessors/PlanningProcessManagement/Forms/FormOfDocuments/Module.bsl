#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	FillPropertyValues(ThisForm,
		Parameters, 
		"Scenario, PlanProfile, Products, Characteristic, Purpose, BeginOfPeriod, PeriodEnding, DataType");
	ListOfPlanProfiles.LoadValues(Parameters.ListOfPlanProfiles);
	FillOutPlans();
	
	IsFolder = Common.ObjectAttributeValue(PlanProfile, "IsFolder");
	If Not ValueIsFilled(Products) Then
		Items.PlansCount.Visible = False;
	EndIf;
	If ValueIsFilled(IsFolder) And Not IsFolder Then
		Items.PlansPlanProfile.Visible = False;
	EndIf;
	
	MessageText = NStr("vi = '%PlanningObject%%PlanProfile% %OwnGoods% cho kỳ từ %BeginOfPeriod% đến %PeriodEnding%';
						|ru = '%PlanningObject%%PlanProfile% %OwnGoods%за период с %BeginOfPeriod% по %PeriodEnding%';
						|en = '%PlanningObject%%PlanProfile% %OwnGoods%for the period from %BeginOfPeriod% to %PeriodEnding%'; fa = '%PlanningObject%%PlanProfile% %OwnGoods%for the period from %BeginOfPeriod% to %PeriodEnding%';
						|it = '%PlanningObject%%PlanProfile% %OwnGoods%за период с %BeginOfPeriod% по %PeriodEnding%';
						|pl = '%PlanningObject%%PlanProfile% %OwnGoods%za okres od %BeginOfPeriod% do %PeriodEnding%';
						|tr = '%PlanningObject%%PlanProfile% %OwnGoods%dönemi için%BeginOfPeriod% tarihinden %PeriodEnding% tarihine kadar'");
	
	If ValueIsFilled(PlanProfile) Then
		If IsFolder Then
			MessageText = StrReplace(MessageText, "%PlanningObject%", NStr("vi = 'Kế hoạch cho giai đoạn lập kế hoạch';
																			|ru = 'Планы по этапу планирования';
																			|en = 'Plans by planning stage'; fa = 'Plans by planning stage';
																			|it = 'Piani per fase di pianificazione';
																			|pl = 'Plany według etapu planowania';
																			|tr = 'Planlama aşamasına göre planlar'") + " ");
		Else
			MessageText = StrReplace(MessageText, "%PlanningObject%", NStr("vi = 'Kế hoạch theo loại kế hoạch';
																			|ru = 'Планы по виду плана';
																			|en = 'Plans by plan profile'; fa = 'Plans by plan profile';
																			|it = 'Piani per tipo di piano';
																			|pl = 'Plany według rodzaju planu';
																			|tr = 'Plan profiline göre planlar'") + " ");
		EndIf;
		MessageText = StrReplace(MessageText, "%PlanProfile%", PlanProfile);
	Else
		MessageText = StrReplace(MessageText, "%PlanningObject%", NStr("vi = 'Tất cả các kế hoạch';
																		|ru = 'Все планы';
																		|en = 'All plans'; fa = 'All plans';
																		|it = 'Tutti i piani';
																		|pl = 'Wszystkie plany';
																		|tr = 'Tüm planlar'"));
		MessageText = StrReplace(MessageText, "%PlanProfile%", PlanProfile);
	EndIf;
	If ValueIsFilled(Products) Then
		MessageText = StrReplace(MessageText, "%OwnGoods%", NStr("vi = 'theo %Products%%Characteristic%%Purpose%';
																|ru = 'по %Products%%Characteristic%%Purpose%';
																|en = 'by %Products%%Characteristic%%Purpose%'; fa = 'by %Products%%Characteristic%%Purpose%';
																|it = 'per %Products%%Characteristic%%Purpose%';
																|pl = 'według %Products%%Characteristic%%Purpose%';
																|tr = '%Products%%Characteristic%%Purpose% değerlerine göre'") + " ");
		MessageText = StrReplace(MessageText, "%Products%", Products);
		If ValueIsFilled(Characteristic) Then
			MessageText = StrReplace(MessageText, "%Characteristic%", ", " + Characteristic );
		Else
			MessageText = StrReplace(MessageText, "%Characteristic%", "");
		EndIf;
		If ValueIsFilled(Purpose) Then
			MessageText = StrReplace(MessageText, "%Purpose%", ", " + Purpose);
		Else
			MessageText = StrReplace(MessageText, "%Purpose%", "");
		EndIf;
		
	Else
		MessageText = StrReplace(MessageText, "%OwnGoods%", "");
	EndIf;
	
	MessageText = StrReplace(MessageText, "%BeginOfPeriod%", BeginOfPeriod);
	MessageText = StrReplace(MessageText, "%PeriodEnding%", PeriodEnding);
	
	LabelTextExplanation = MessageText;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SalesPlan"
		Or EventName = "Write_PurchasePlan"
		Or EventName = "Write_PlanOfGoodsStock"
		Or EventName = "Write_ProductionPlan"
		Or EventName = "Write_AssemblyDisassemblyPlan"
		Or EventName = "Write_InventoryConsumptionPlan" Then
		FillOutPlans();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Plans.Count() = 0 Then
		Cancel = True;
	EndIf;
	
	If Plans.Count() = 1 Then
		Cancel = True;
		FormParametersCurRow = New Structure();
		FormParametersCurRow.Insert("Products", Products);
		FormParametersCurRow.Insert("Characteristic", Characteristic);
		FormParametersCurRow.Insert("Purpose", Purpose);
		
		
		If TypeOf(Plans[0].Document) = Type("DocumentRef.AdjustmentOfPlannedDemand") Then
			ShowValue(, Plans[0].Document);
		Else
			If ValueIsFilled(Plans[0].Document) Then
				FormParameters = New Structure("Key, CurrentRow", Plans[0].Document, FormParametersCurRow);
			Else
				FillingValues = New Structure();
				FillingValues.Insert("Scenario", Scenario);
				FillingValues.Insert("PlanProfile", Plans[0].PlanProfile);
				FillingValues.Insert("BeginOfPeriod", BeginOfPeriod);
				FillingValues.Insert("PeriodEnding", PeriodEnding);
				
				FormParameters = New Structure("FillingValues", FillingValues);
			EndIf;
			PlanTypeString = PlanTypeString(Plans[0].PlanProfile);
			OpenForm("Document." + PlanTypeString + ".ObjectForm", 
			FormParameters);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusInPreparation(Command)
	
	SetStatus("UnderPreparation", NStr("vi = 'Đang chuẩn bị';
										|ru = 'В подготовке';
										|en = 'Under development'; fa = 'در حال توسعه';
										|it = 'In preparazione';
										|pl = 'W przygotowaniu';
										|tr = 'Hazırlanma işleminde'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusOnApproval(Command)
	
	SetStatus("AwaitingConfirmation", NStr("vi = 'Đang làm việc';
											|ru = 'В работе';
											|en = 'Submitted'; fa = 'ارسال‌شده';
											|it = 'In esecuzione';
											|pl = 'Wykonuje się';
											|tr = 'İşleniyor'"));
	
EndProcedure

&AtClient
Procedure SetTheConfirmedStatus(Command)
	
	SetStatus("Upholded", NStr("vi = 'Đã duyệt';
								|ru = 'Утвержден';
								|en = 'Confirmed'; fa = 'تأییدشده';
								|it = 'Confermato';
								|pl = 'Zatwierdzony';
								|tr = 'Onaylandı'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusToCanceled(Command)
	
	SetStatus("RolledBack_", NStr("vi = 'Hủy bỏ';
									|ru = 'Отменен';
									|en = 'Canceled'; fa = 'لغوشده';
									|it = 'Annullato';
									|pl = 'Canceled';
									|tr = 'İptal edildi'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure PlansSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentData = Items.Plans.CurrentData;
	If ValueIsFilled(CurrentData.Document) Then
		
		If TypeOf(CurrentData.Document) = Type("DocumentRef.AdjustmentOfPlannedDemand") Then
			ShowValue(, CurrentData.Document);
		Else
			FormParameters = New Structure("Key", CurrentData.Document);
			If ValueIsFilled("Products") Then
				FormParametersCurRow = New Structure();
				FormParametersCurRow.Insert("Products", Products);
				FormParametersCurRow.Insert("Characteristic", Characteristic);
				FormParametersCurRow.Insert("Purpose", Purpose);
				FormParameters.Insert("CurrentRow", FormParametersCurRow);
			EndIf;
			
			PlanTypeString = PlanTypeString(CurrentData.PlanProfile);
			OpenForm("Document." + PlanTypeString + ".ObjectForm", 
			FormParameters);
		EndIf;
		
	Else
		
		FillingValues = New Structure();
		FillingValues.Insert("Scenario", Scenario);
		FillingValues.Insert("PlanProfile", CurrentData.PlanProfile);
		FillingValues.Insert("BeginOfPeriod", BeginOfPeriod);
		FillingValues.Insert("PeriodEnding", PeriodEnding);
		
		PlanTypeString = PlanTypeString(CurrentData.PlanProfile);
		OpenForm("Document." + PlanTypeString + ".ObjectForm", 
			New Structure("FillingValues", FillingValues));
		
	EndIf;
	ThisForm.Close()
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PlansDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Plans.Document");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo mới';
													|ru = 'Создать';
													|en = 'Create'; fa = 'ایجاد';
													|it = 'Creare';
													|pl = 'Create';
													|tr = 'Oluştur'"));
	
EndProcedure

&AtServer
Procedure FillOutPlans()
	
	If ValueIsFilled(Products) Then
		Query = New Query();
		Query.Text = 
		"SELECT
		|	SUM(PurchasePlansTurnovers.CountTurnover) AS Count,
		|	SUM(PurchasePlansTurnovers.DemandRangeIsSpecifiedTurnover) AS DemandRangeIsSpecifiedTurnover,
		|	Document.Ref AS Document,
		|	Document.PointInTime AS PointInTime,
		|	Document.Date AS DocumentDate,
		|	Document.Number AS DocumentNumber,
		|	Document.Status AS Status,
		|	Document.PlanProfile AS PlanProfile,
		|	Document.PlanProfile.PlanType AS PlanType,
		|	CAST(Document.Comment AS STRING(255)) AS Comment
		|FROM
		|	AccumulationRegister.PurchasePlans.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS PurchasePlansTurnovers
		|		LEFT JOIN Document.PurchasePlan AS Document
		|		ON PurchasePlansTurnovers.PurchasePlan = Document.Ref
		|WHERE
		|	&Receipt
		|	AND Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(ReleasePlansProducts_Turnovers.CountTurnover),
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.ReleasePlansProducts_.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS ReleasePlansProducts_Turnovers
		|		LEFT JOIN Document.ProductionPlan AS Document
		|		ON ReleasePlansProducts_Turnovers.ProductionPlan = Document.Ref
		|WHERE
		|	&Receipt
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|	
		|UNION ALL
		|
		|SELECT
		|	0,
		|	SUM(ProductionPlansTurnovers.DemandRangeIsSpecifiedTurnover),
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.ProductionPlans.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS ProductionPlansTurnovers
		|		LEFT JOIN Document.ProductionPlan AS Document
		|		ON ProductionPlansTurnovers.ProductionPlan = Document.Ref
		|WHERE
		|	&Receipt
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(MaterialConsumptionPlansTurnovers.CountTurnover),
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.MaterialConsumptionPlans.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS MaterialConsumptionPlansTurnovers
		|		LEFT JOIN Document.ProductionPlan AS Document
		|		ON MaterialConsumptionPlansTurnovers.ProductionPlan = Document.Ref
		|WHERE
		|	&Expense
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(SalesPlansTurnovers.CountTurnover),
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.SalesPlans.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS SalesPlansTurnovers
		|		LEFT JOIN Document.SalesPlan AS Document
		|		ON SalesPlansTurnovers.SalesPlan = Document.Ref
		|WHERE
		|	&Expense
		|	AND Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(InventoryConsumptionPlansTurnovers.CountTurnover),
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.InventoryConsumptionPlans.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS InventoryConsumptionPlansTurnovers
		|		LEFT JOIN Document.InventoryConsumptionPlan AS Document
		|		ON InventoryConsumptionPlansTurnovers.InventoryConsumptionPlan = Document.Ref
		|WHERE
		|	&Expense
		|	AND Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(TurnoverBalancePlans.CountTurnover),
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.PlansOfGoodsStock.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS TurnoverBalancePlans
		|		LEFT JOIN Document.PlanOfGoodsStock AS Document
		|		ON TurnoverBalancePlans.PlanOfGoodsStock = Document.Ref
		|WHERE
		|	&OpeningBalance
		|	AND Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(AssemblyPlansDisassemblyRevolutions.CountTurnover),
		|	SUM(AssemblyPlansDisassemblyRevolutions.DemandRangeIsSpecifiedTurnover),
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.AssemblyDisassemblyPlans.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS AssemblyPlansDisassemblyRevolutions
		|		LEFT JOIN Document.AssemblyDisassemblyPlan AS Document
		|		ON AssemblyPlansDisassemblyRevolutions.AssemblyDisassemblyPlan = Document.Ref
		|WHERE
		|	&Receipt
		|	AND Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(PlansForConsumptionOfComponentsTurnover.CountTurnover),
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.ComponentsConsumptionPlans.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS PlansForConsumptionOfComponentsTurnover
		|		LEFT JOIN Document.AssemblyDisassemblyPlan AS Document
		|		ON PlansForConsumptionOfComponentsTurnover.AssemblyDisassemblyPlan = Document.Ref
		|WHERE
		|	&Expense
		|	AND Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|UNION ALL
		|
		|SELECT
		|	SUM(AdjustmentsToPlannedDemandsTurnovers.CountTurnover),
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	AccumulationRegister.AdjustmentsToPlannedDemands.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			Scenario = &Scenario
		|				AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|					OR PlanProfile IN (&ListOfPlanProfiles))
		|				AND (Products = &Products
		|						AND Characteristic = &Characteristic
		|						AND Purpose = &Purpose
		|					OR &WithoutProducts)) AS AdjustmentsToPlannedDemandsTurnovers
		|		LEFT JOIN Document.AdjustmentOfPlannedDemand AS Document
		|		ON AdjustmentsToPlannedDemandsTurnovers.AdjustmentOfPlannedDemand = Document.Ref
		|WHERE
		|	&ExpenseAdjustment
		|	AND Document.Posted
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|GROUP BY
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|
		|ORDER BY
		|	PointInTime";
	Else
		Query = New Query();
		Query.Text = 
		"SELECT
		|	0 AS Count,
		|	Document.Ref AS Document,
		|	Document.PointInTime AS PointInTime,
		|	Document.Date AS DocumentDate,
		|	Document.Number AS DocumentNumber,
		|	Document.Status AS Status,
		|	Document.PlanProfile AS PlanProfile,
		|	Document.PlanProfile.PlanType AS PlanType,
		|	CAST(Document.Comment AS STRING(255)) AS Comment
		|FROM
		|	Document.PurchasePlan AS Document
		|WHERE
		|	Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|UNION ALL
		|
		|SELECT
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	Document.ProductionPlan AS Document
		|WHERE
		|	Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|UNION ALL
		|
		|SELECT
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	Document.SalesPlan AS Document
		|WHERE
		|	Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|UNION ALL
		|
		|SELECT
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	Document.SalesPlanByCategories AS Document
		|WHERE
		|	Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|UNION ALL
		|
		|SELECT
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	Document.InventoryConsumptionPlan AS Document
		|WHERE
		|	Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|UNION ALL
		|
		|SELECT
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	Document.PlanOfGoodsStock AS Document
		|WHERE
		|	Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|UNION ALL
		|
		|SELECT
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	Document.AssemblyDisassemblyPlan AS Document
		|WHERE
		|	Document.BeginOfPeriod <= &PeriodEnding
		|	AND Document.PeriodEnding >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|UNION ALL
		|
		|SELECT
		|	0,
		|	Document.Ref,
		|	Document.PointInTime,
		|	Document.Date,
		|	Document.Number,
		|	Document.Status,
		|	Document.PlanProfile,
		|	Document.PlanProfile.PlanType,
		|	CAST(Document.Comment AS STRING(255))
		|FROM
		|	Document.AdjustmentOfPlannedDemand AS Document
		|WHERE
		|	Document.Period <= &PeriodEnding
		|	AND Document.Period >= &BeginOfPeriod
		|	AND Document.Posted
		|	AND Document.Status.Order >=1
		|	AND Document.Scenario = &Scenario
		|	AND (&PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
		|			OR Document.PlanProfile IN (&ListOfPlanProfiles))
		|
		|ORDER BY
		|	PointInTime";
	EndIf;
		
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("ListOfPlanProfiles", ListOfPlanProfiles.UnloadValues());
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("WithoutProducts", Not ValueIsFilled(Products));
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("OpeningBalance", DataType = "OpeningBalance" Or DataType = "");
	Query.SetParameter("Receipt", DataType = "Receipt" Or DataType = "");
	Query.SetParameter("Expense", DataType = "Expense" Or DataType = "");
	Query.SetParameter("ExpenseAdjustment", DataType = "ExpenseAdjustment" Or DataType = "" Or (DataType = "Expense" And Not ValueIsFilled(PlanProfile)));
	SetPrivilegedMode(True);
	TableOfPlans = Query.Execute().Unload();
	SetPrivilegedMode(False);
	Plans.Load(TableOfPlans);
	
	If Not ValueIsFilled(Products)
		And ValueIsFilled(PlanProfile) Then
		If Common.ObjectAttributeValue(PlanProfile, "IsFolder") Then
			
			For Each ListItem In ListOfPlanProfiles Do
				NewRow = Plans.Add();
				NewRow.PlanProfile = ListItem.Value;
				NewRow.Document = Undefined
			EndDo;
			
		Else
			
			NewRow = Plans.Add();
			NewRow.Document = Undefined;
			NewRow.PlanProfile =  PlanProfile;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function PlanTypeString(PlanProfile)
	PlanType = Common.ObjectAttributeValue(PlanProfile, "PlanType");
	If PlanType = Enums.TypesOfPlans.PurchasePlan Then
		LinePlanType = "PurchasePlan";
	ElsIf PlanType = Enums.TypesOfPlans.PlanOfGoodsStock Then
		LinePlanType = "PlanOfGoodsStock";
	ElsIf PlanType = Enums.TypesOfPlans.SalesPlan Then
		LinePlanType = "SalesPlan";
	ElsIf PlanType = Enums.TypesOfPlans.SalesPlanByCategories Then
		LinePlanType = "SalesPlanByCategories";
	ElsIf PlanType = Enums.TypesOfPlans.ProductionPlan Then
		LinePlanType = "ProductionPlan";
	ElsIf PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		LinePlanType = "AssemblyDisassemblyPlan";
	ElsIf PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan Then
		LinePlanType = "InventoryConsumptionPlan";
	EndIf;
	
	Return LinePlanType
EndFunction

&AtClient
Procedure SetStatus(Status, StatusText)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Plans);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;

	HighlightedAdjustments = New Array;
	DedicatedPlans = New Array;
	
	For Each IndexOf In SelectedRows Do
		DocumentReference = Plans.FindByID(IndexOf).Document;
		If TypeOf(DocumentReference) = Type("DocumentRef.AdjustmentOfPlannedDemand") Then
			If (Status = "Upholded" Or Status = "RolledBack_") Then 
				HighlightedAdjustments.Add(DocumentReference);
			EndIf;
		ElsIf ValueIsFilled(DocumentReference) Then
			DedicatedPlans.Add(DocumentReference);
		EndIf;
	EndDo;
	
	If HighlightedAdjustments.Count() = 0
		And DedicatedPlans.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
								|ru = 'Команда не может быть выполнена для указанного объекта!';
								|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
								|it = 'Il comando non può essere eseguito per oggetto indicato!';
								|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
								|tr = 'Komut belirtilen nesne için uygulanamaz'"));
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các chứng từ được chọn trong danh sách sẽ có trạng thái ""%Status%"". Tiếp tục?';
					|ru = 'У выделенных в списке документов будет установлен статус ""%Status%"". Продолжить?';
					|en = 'The ""%Status%"" status will be set for the documents selected in the list. Continue?'; fa = 'The ""%Status%"" status will be set for the documents selected in the list. Continue?';
					|it = 'Per i documenti evidenziati nell''elenco verrà impostato lo stato ""%Status%"". Continuare?';
					|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""%Status%"". Kontynuować?';
					|tr = 'Listede seçilen belgelerin durumu ""%Status%"" olarak kurulacak. Devam edilsin mi?'");
	QueryText = StrReplace(QueryText, "%Status%", StatusText);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Status", Status);
	AdditionalParameters.Insert("StatusText", StatusText);
	AdditionalParameters.Insert("HighlightedAdjustments", HighlightedAdjustments);
	AdditionalParameters.Insert("DedicatedPlans", DedicatedPlans);
	
	Notification = New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(Result, AdditionalParameters) Export 
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
		
	ClearMessages();
	ProcessedItemsCount = 0;
	
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
		AdditionalParameters.DedicatedPlans, 
		AdditionalParameters.Status);
		
	AdjustmentStatus = ?(AdditionalParameters.Status = "Upholded", "Upholded_", "RolledBack");
	ProcessedItemsCount = ProcessedItemsCount + GeneralPurposeTMServerCall.SetStatusOfDocuments(
		AdditionalParameters.HighlightedAdjustments, 
		AdjustmentStatus);
		
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.Plans, 
		ProcessedItemsCount, 
		AdditionalParameters.DedicatedPlans.Count() + AdditionalParameters.HighlightedAdjustments.Count(), 
		AdditionalParameters.StatusText);
		
	FillOutPlans();
	
EndProcedure

#EndRegion
