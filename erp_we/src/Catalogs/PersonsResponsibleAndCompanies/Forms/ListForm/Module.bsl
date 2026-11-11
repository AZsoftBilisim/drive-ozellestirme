
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	EstablishOrganization();

	If GetFunctionalOption("BaseVersion") Then
		Items.Individual.Title = NStr("vi = 'Nhân viên';
										|ru = 'Сотрудник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Pracownik';
										|tr = 'Çalışan'");
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Not Items.CompanyFilter.Visible Then
		Settings.Delete("Organization");
	Else
		Organization = Settings.Get("Organization");
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Owner",
			Organization,
			DataCompositionComparisonType.Equal,,
			ValueIsFilled(Organization));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Owner",
		Organization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Organization));
	
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
Procedure EstablishOrganization()
	
	If Parameters.Property("Filter")
	 And Parameters.Filter.Property("Owner") Then
		
		Organization = Parameters.Filter.Owner;
		
		Items.CompanyFilter.Visible = False;
		Items.Owner.Visible 		= False;
		
	Else
		Items.Owner.Visible = GetFunctionalOption("UseMultipleCompanies");
	EndIf;
	
EndProcedure

#EndRegion
