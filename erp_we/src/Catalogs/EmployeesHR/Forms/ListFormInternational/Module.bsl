
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBarForm;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	CatalogsSalaryAndPersonnelServer.EmployeesWhenCreatingListFormAtServer(ThisObject, Cancel, StandardProcessing);
	
	HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed = 
		Common.CommonSettingsStorageLoad("ListOfEmployees", "HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed", True);
	SetSelectionOfEmployeesInArchive(ThisForm, HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed, False);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure("Key", RowSelected);
	OpenForm("Catalog.EmployeesHR.Form.ItemFormInternational", FormParameters,,); 
	
	
EndProcedure

&AtClient
Procedure HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformedOnChange(Item)

	SetSelectionOfEmployeesInArchive(ThisObject, HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateElement(Command)
	
	FormParameters = New Structure("", );
	OpenForm("Catalog.EmployeesHR.Form.ItemFormInternational", FormParameters, , 
		, , );
	
EndProcedure

&AtClient
Procedure OfOperationsAreNotPerformed(Command)
	
		If Items.List.SelectedRows.Count() > 0 Then
		
		InstallOperation = True;
		For Each EmployeeLink In Items.List.SelectedRows Do
			
			If Items.List.RowData(EmployeeLink).InArchive Then
				InstallOperation = False;
				Break;
			EndIf;
			
		EndDo;
		
		If InstallOperation Then
			QueryText = NStr("vi = 'Đánh dấu tất cả thao tác theo %1 đã được hoàn tất';
							|ru = 'Установить отметку того, что все операции по %1 завершены';
							|en = 'Set the mark that all operations for %1 are completed'; fa = 'Set the mark that all operations for %1 are completed';
							|it = 'Set the mark that all operations for %1 are completed';
							|pl = 'Set the mark that all operations for %1 are completed';
							|tr = '%1 ile ilgili tüm işlemlerin tamamlandığına dair işareti koy'") + "?";
		Else
			QueryText = NStr("vi = 'Đánh dấu tất cả thao tác theo %1 đã được hoàn tất';
							|ru = 'Снять отметку того, что все операции по %1 завершены';
							|en = 'Clear the mark that all operations for %1 are completed'; fa = 'Clear the mark that all operations for %1 are completed';
							|it = 'Clear the mark that all operations for %1 are completed';
							|pl = 'Clear the mark that all operations for %1 are completed';
							|tr = '%1 ile ilgili tüm işlemlerin tamamlandığına dair işareti kaldır'") + "?";
		EndIf;
		
		If Items.List.SelectedRows.Count() = 1 Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				QueryText,
				NStr("vi = 'nhân viên';
					|ru = 'сотруднику';
					|en = 'employee'; fa = 'employee';
					|it = 'employee';
					|pl = 'employee';
					|tr = 'Çalışana'") + " " + Items.List.SelectedRows[0]
			);
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				QueryText,
				NStr("vi = 'nhân viên';
					|ru = 'сотрудникам';
					|en = 'employees'; fa = 'employees';
					|it = 'employees';
					|pl = 'employees';
					|tr = 'Çalışanlara'")
			);
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("InstallOperation", InstallOperation);
		AdditionalParameters.Insert("EmployeesHR", Items.List.SelectedRows);
		AdditionalParameters.Insert("ListFormElement", Items.List);
		
		Notification = New CallbackDescription("OfOperationsAreNotPerformedCompletion", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNoCancel, , DialogReturnCode.No);
		
	EndIf; 

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetSelectionOfEmployeesInArchive(Form, Use, RememberSetValue)
	
	If Use Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.List, "InArchive", False);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(
			Form.List, "InArchive");
	EndIf;
	
	If RememberSetValue Then
		RememberToHideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed(Use);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure RememberToHideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed(HideEmployees)
	
	Common.CommonSettingsStorageSave("ListOfEmployees", "HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed", HideEmployees);
	
EndProcedure

&AtClient
Procedure OfOperationsAreNotPerformedCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		OperationsAreNotPerformedATServer(AdditionalParameters.EmployeesHR, AdditionalParameters.InstallOperation);
		
		Items.List.Refresh();
	EndIf; 
	
EndProcedure

&AtServer
Procedure OperationsAreNotPerformedATServer(EmployeesHR, InstallOperation)
	
	ValueOfDetailsInArchive = Common.ObjectsAttributeValue(EmployeesHR, "InArchive");
	For Each ObjectDetails In ValueOfDetailsInArchive Do
		
		If ObjectDetails.Value <> InstallOperation Then
			
			EmployeeObject_ = ObjectDetails.Key.GetObject();
			EmployeeObject_.InArchive = InstallOperation;
			EmployeeObject_.Write();
			
		EndIf; 
		
	EndDo;
	
EndProcedure

#EndRegion
