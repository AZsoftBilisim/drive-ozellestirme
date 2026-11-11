
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReferenceOrder", ReferenceOrder);
	Parameters.Property("AmountToPay", AmountToPay);
	Parameters.Property("Currency", Currency);
	Parameters.Property("Warehouse", Warehouse);
	
	UpdateFormData();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAProcessCommand(Command)
	
	Cancel = False;
	
	AcceptPaymentAndIssueReceipt(Cancel);
	
	If Not Cancel Then
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFormData()
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	AmountToPayPresentation = Module.AmountToPayPresentation(ThisForm);
	
	Items.DecorationAmountToBePaid.Title = New FormattedString(AmountToPayPresentation,
		StyleFonts.EnlargedTextFontSelectedAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	OverrideCurProcessCommand();
		
EndProcedure

#Region ProcessActions

&AtServer
Procedure OverrideCurProcessCommand()
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.OverrideCurProcessCommand(ThisForm);
	
EndProcedure

&AtServer
Procedure AcceptPaymentAndIssueReceipt(Cancel = False) 
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	Module.CreateAcquiringOperation(ReferenceOrder, AmountToPay, Cancel);
	
	If StrFind(CurrentAction1, "IssueReceipt")
		And Not Cancel Then
		Module.IssueReceipt(ReferenceOrder, Cancel);
	EndIf;
	
	If Not Cancel Then
		Module.CompleteDelivery(ReferenceOrder);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
