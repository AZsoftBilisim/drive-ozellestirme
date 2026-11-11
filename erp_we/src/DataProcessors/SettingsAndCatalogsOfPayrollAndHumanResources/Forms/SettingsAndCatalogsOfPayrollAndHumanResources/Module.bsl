#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ManagingElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "Write_ConstantsSet" Then
		// The program settings in the administration panels have been changed
		ManagingElements();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenEmployeeWorkSchedules(Command)
	
	OpenForm("Catalog.Calendars.Form.ListForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTypesOfWorkingHours(Command)
	
	OpenForm("Catalog.PayCodesHR.Form.ListForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTypesOfStandardDeductions(Command)

	OpenForm("Catalog.StandardDeductionKinds.ListForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTypesOfAccrualsAndDeductions(Command)
	
	OpenForm("Catalog.AccrualAndDeductionKinds.ListForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure Open_TypesOfTaxesAndContributions(Command)
	
	OpenForm("Catalog.TaxContributionKinds.ListForm",, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()

	RightToAccessCalendars = AccessRight("View", Metadata.Catalogs.Calendars);
	Items.OpenWorkSchedules.Visible = RightToAccessCalendars;
	
	RightOfAccessTypesOfWorkingHours = AccessRight("View", Metadata.Catalogs.PayCodesHR);
	Items.OpenTypesOfWorkingHours.Visible = RightOfAccessTypesOfWorkingHours;

EndProcedure

#EndRegion
