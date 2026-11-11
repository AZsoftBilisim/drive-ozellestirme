
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers
	
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	
	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("CurrentDate");
	If Parameter <> Undefined Then
		If Not ValueIsFilled(Parameter.Value) Or Not Parameter.Use Then
			Parameter.Value = CurrentSessionDate();
			Parameter.Use = True;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf