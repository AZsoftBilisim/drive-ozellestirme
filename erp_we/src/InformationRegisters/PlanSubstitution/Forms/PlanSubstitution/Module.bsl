#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FillOutReplacementAndReplacementPlans();
	If Parameters.FormattedStringURL = "Replaced_" Then
		Items.SubstituteAndSubstitutedPlans.CurrentPage = Items.TheSubstitutedPlansPage;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubstitutePlansSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowValue(,Items.SubstitutePlans.CurrentData.ReplacementPlan_3);
EndProcedure

&AtClient
Procedure SubstitutedPlansSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowValue(,Items.SubstitutedPlans.CurrentData.SubstitutedPlan);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillOutReplacementAndReplacementPlans()
	
	ObjectManager = Common.ObjectManagerByRef(Parameters.Ref);
	Query = ObjectManager.RequestReplacementAndReplacementPlans(Parameters);
	
	RequestPackage = Query.ExecuteBatch();
	VTReplacementPlans = RequestPackage[0].Unload();
	VTReplacementPlans_ = RequestPackage[1].Unload();
		
	For Each String In VTReplacementPlans Do
		NewRow = SubstitutePlans.Add();
		FillPropertyValues(NewRow, String);
		NewRow.ReplacementPeriod.StartDate = String.BeginOfPeriod;
		NewRow.ReplacementPeriod.EndDate = String.PeriodEnding;
	EndDo;
	
	For Each String In VTReplacementPlans_ Do
		NewRow = SubstitutedPlans.Add();
		FillPropertyValues(NewRow, String);
		NewRow.ReplacementPeriod.StartDate = String.BeginOfPeriod;
		NewRow.ReplacementPeriod.EndDate = String.PeriodEnding;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

EndProcedure

#EndRegion