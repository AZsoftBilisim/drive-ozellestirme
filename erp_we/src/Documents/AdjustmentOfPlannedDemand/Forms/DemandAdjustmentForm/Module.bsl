
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters, "Scenario, PlanProfile, Plan, Products, Characteristic, Purpose, Period");
	
	Parameters.Property("CreateChangeAdjustment", CreateChangeAdjustment);
	
	If ValueIsFilled(Adjusting) Then
		
		TabularPartReductionOfNeeds = Common.ObjectAttributeValue(Adjusting, "DecreasedDemands");
		ForAdjustment = TabularPartReductionOfNeeds[0].Count;
		
		TabularPartIncreasingNeeds = Common.ObjectAttributeValue(Adjusting, "IncreasedDemand");
		If TabularPartIncreasingNeeds.Count() > 0 Then
			ToTheAdjustmentOfTheAdjustment = TabularPartIncreasingNeeds[0].Count;
			NomenclatureAdjustment = TabularPartIncreasingNeeds[0].Products;
			Balance = 200;
		EndIf;
		
		Items.NomenclatureAdjustment.Enabled = False;
		Items.FeatureAdjustment.Enabled = False;
		Items.PurposeAdjustment.Enabled = False;
		
	EndIf;
	
	//Calculate the need and the balance
	Demand= 900;
	
	ToSupply = Demand - ForAdjustment;
	ToEnsureTheAdjustment = ToTheAdjustmentOfTheAdjustment - Balance;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region EventHandlers

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AdjustDemand(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	AdjustmentStructure = New Structure();
	AdjustmentStructure.Insert("Plan", Plan);
	AdjustmentStructure.Insert("Scenario", Scenario);
	AdjustmentStructure.Insert("PlanProfile", PlanProfile);
	AdjustmentStructure.Insert("Period", Period);
	AdjustmentStructure.Insert("Products", Products);
	AdjustmentStructure.Insert("Characteristic", Characteristic);
	AdjustmentStructure.Insert("Purpose", Purpose);
	AdjustmentStructure.Insert("NomenclatureAdjustment", NomenclatureAdjustment);
	AdjustmentStructure.Insert("FeatureAdjustment", FeatureAdjustment);
	AdjustmentStructure.Insert("PurposeAdjustment", PurposeAdjustment);
	AdjustmentStructure.Insert("ForAdjustment", ForAdjustment);
	AdjustmentStructure.Insert("Demand", Demand);
	AdjustmentStructure.Insert("ToTheAdjustmentOfTheAdjustment", ToTheAdjustmentOfTheAdjustment);
	AdjustmentStructure.Insert("ToSupply", ToSupply);
	AdjustmentStructure.Insert("ToEnsureTheAdjustment", ToEnsureTheAdjustment);
	
	If CreateChangeAdjustment Then
		If ValueIsFilled(Adjusting) Then
			ChangeAdjustment(AdjustmentStructure);
		Else
			Adjusting = CreateAdjustment(AdjustmentStructure);
		
			If Adjusting = Undefined Then
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	AdjustmentStructure.Insert("Adjusting", Adjusting);
	Close(AdjustmentStructure);
	
EndProcedure

#EndRegion

#Region Private

Procedure ChangeAdjustment(FillingData)
	
	DocumentObject = Adjusting.GetObject();
	DocumentObject.IncreasedDemand.Clear();
	DocumentObject.DecreasedDemands.Clear();
	DocumentObject.Fill(FillingData);
	
	Error = Not DocumentObject.CheckFilling();
	
	If Not Error Then
		DocumentObject.Write(DocumentWriteMode.Posting);
	EndIf;
	
EndProcedure

Function CreateAdjustment(FillingData)
	
	DocumentObject = Documents.AdjustmentOfPlannedDemand.CreateDocument();
	DocumentObject.Fill(FillingData);
	
	Error = Not DocumentObject.CheckFilling();
	
	If Not Error Then
		
		DocumentObject.Write(DocumentWriteMode.Posting);
		Return DocumentObject.Ref
		
	EndIf;
			
	Return Undefined
EndFunction

&AtClient
Procedure ToReplaceOnChange(Item)
	ToSupply = Demand - ForAdjustment;
EndProcedure

&AtClient
Procedure ToSupply_OnChange(Item)
	ForAdjustment = Demand - ToSupply;
EndProcedure

&AtClient
Procedure ToTheAdjustmentOfTheAdjustmentOnChange(Item)
	ToEnsureTheAdjustment = ToTheAdjustmentOfTheAdjustment - Balance;
EndProcedure

&AtClient
Procedure ToEnsureTheAdjustmentOnChange(Item)
	ToTheAdjustmentOfTheAdjustment = Balance - ToEnsureTheAdjustment;
EndProcedure

&AtClient
Procedure MoveTo_(Command)
	ToTheAdjustmentOfTheAdjustment = ToTheAdjustmentOfTheAdjustment + ForAdjustment;
	ToEnsureTheAdjustment = ToEnsureTheAdjustment - ForAdjustment;
	
	ToSupply = ToSupply + ForAdjustment;
	ForAdjustment = 0;
EndProcedure

#EndRegion