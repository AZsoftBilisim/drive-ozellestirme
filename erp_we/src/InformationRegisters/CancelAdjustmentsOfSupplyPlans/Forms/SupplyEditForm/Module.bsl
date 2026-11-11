
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Products = Parameters.Products;
	Characteristic = Parameters.Characteristic;
	Purpose = Parameters.Purpose;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	CalculationOfPlanShortagesByStages.Deficit AS Deficit,
	|	CalculationOfPlanShortagesByStages.Receipt AS Receipt	
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.Characteristic = &Characteristic
	|	AND CalculationOfPlanShortagesByStages.Products = &Products
	|	AND CalculationOfPlanShortagesByStages.Purpose = &Purpose
	|	AND CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod = &PlanningPeriod";
	Query.SetParameter("Products", Parameters.Products);
	Query.SetParameter("Characteristic", Parameters.Characteristic);
	Query.SetParameter("Purpose", Parameters.Purpose);
	Query.SetParameter("PlanProfile", Parameters.PlanProfile);
	Query.SetParameter("PlanningPeriod", Parameters.Period);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Demand = Selection.Deficit + Selection.Receipt;
	Else
		//Debugging, when it was not calculated, you can take the need from the stage
		Demand = 0;
	EndIf;
	
	If TypeOf(Parameters.Plan) = Type("DocumentRef.PurchasePlan") Then
		Items.ToSupply_.Title = NStr("vi = 'Mua hàng';
									|ru = 'Закупить';
									|en = 'Purchase'; fa = 'خرید';
									|it = 'Acquistare';
									|pl = 'Purchase';
									|tr = 'Satın al'");
		Title = NStr("vi = 'Điều chỉnh kế hoạch mua hàng';
					|ru = 'Корректировка плана закупки';
					|en = 'Adjustment of purchase plan'; fa = 'تعدیل برنامه خرید';
					|it = 'Корректировка плана закупки';
					|pl = 'Adjustment of purchase plan';
					|tr = 'Satın alma planının düzenlenmesi'");
	ElsIf TypeOf(Parameters.Plan) = Type("DocumentRef.AssemblyDisassemblyPlan") Then
		Items.ToSupply_.Title = NStr("vi = 'Để thu thập';
									|ru = 'Собрать';
									|en = 'To assemble'; fa = 'برای جمع‌آوری';
									|it = 'Da assemblare';
									|pl = 'To assemble';
									|tr = 'Topla'");
		Title = NStr("vi = 'Điều chỉnh kế hoạch đóng bộ (tách bộ';
					|ru = 'Корректировка плана сборки (разборки';
					|en = 'Adjustment of kitting schedule'; fa = 'Adjustment of kitting schedule';
					|it = 'Корректировка плана сборки (разборки';
					|pl = 'Adjustment of kitting schedule';
					|tr = 'Montaj programı planının düzenlenmesi'");
	Else
		Items.ToSupply_.Title = NStr("vi = 'Kết chuyển';
									|ru = 'Произвести';
									|en = 'Produce'; fa = 'تولید';
									|it = 'Produrre';
									|pl = 'Produce';
									|tr = 'Üret'");
	EndIf;
		
	
	ToSupply_ = Parameters.ToSupply_;
	
	Comment = Parameters.Comment;
	If Parameters.DemandRangeIsSpecified Then
		RangeOfDemandFrom = Parameters.RangeOfDemandFrom;
		RangeOfDemandTo = Parameters.RangeOfDemandTo;
		LimitRangeFrom = ValueIsFilled(RangeOfDemandFrom);
		LimitRangeTo = ValueIsFilled(RangeOfDemandTo);
	Else
		RangeOfDemandFrom = Demand;
		RangeOfDemandTo = Demand;
		LimitRangeTo = True;
		LimitRangeFrom = True;
	EndIf;
	
	UpdateItemAvailability(ThisForm);
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateItemAvailability(Form)
	
	Form.Items.RangeOfDemandFrom.Enabled = Form.LimitRangeFrom;
	Form.Items.RangeOfDemandTo.Enabled = Form.LimitRangeTo;
	
EndProcedure

&AtClient
Procedure ToSupply_OnChange(Item)
	
	If ToSupply_ = 0 Then
		LimitRangeFrom = False;
		LimitRangeTo = False;
	EndIf;
	
	If LimitRangeFrom Then
		RangeOfDemandFrom = Min(ToSupply_, RangeOfDemandFrom);
	EndIf;
	If LimitRangeTo Then
			RangeOfDemandTo = Max(ToSupply_,RangeOfDemandTo);
	EndIf;
	
EndProcedure

&AtClient
Procedure RangeOfDemandFromOnChange(Item)
	LimitRangeFrom = ValueIsFilled(RangeOfDemandFrom);
	UpdateItemAvailability(ThisForm);
EndProcedure

&AtClient
Procedure RangeOfDemandToOnChange(Item)
	LimitRangeTo = ValueIsFilled(RangeOfDemandTo);
	UpdateItemAvailability(ThisForm);
EndProcedure

&AtClient
Procedure LimitRangeToOnChange(Item)
	UpdateItemAvailability(ThisForm);
EndProcedure

&AtClient
Procedure LimitRangeFromOnChange(Item)
	UpdateItemAvailability(ThisForm);
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(Undefined);
EndProcedure

&AtClient
Procedure SetAdjustment(Command)
	
	If Demand = RangeOfDemandFrom 
		And Demand = RangeOfDemandTo
		And LimitRangeFrom = True
		And LimitRangeTo = True Then
		Close(Undefined);
	Else
		SettingsStructure = New Structure();
		SettingsStructure.Insert("SetAdjustment", True);
		SettingsStructure.Insert("ToSupply_", ToSupply_);
		SettingsStructure.Insert("RangeOfDemandFrom", ?(LimitRangeFrom, RangeOfDemandFrom, 0));
		SettingsStructure.Insert("RangeOfDemandTo",?(LimitRangeTo, RangeOfDemandTo, 0));
		SettingsStructure.Insert("Comment", Comment);
		
		Close(SettingsStructure);
	EndIf;
EndProcedure

&AtClient
Procedure CancelAdjustment(Command)
	SettingsStructure = New Structure();
	SettingsStructure.Insert("SetAdjustment", False);
	
	Close(SettingsStructure);
EndProcedure
