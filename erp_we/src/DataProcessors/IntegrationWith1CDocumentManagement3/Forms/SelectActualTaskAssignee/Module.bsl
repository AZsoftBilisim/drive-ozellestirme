#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTOData = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		Parameters.RequiredInteractiveAction.Context);
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOData, "addressees") Then
		For Each XDTORow In XDTOData.addressees Do
			String = TaskRecipients.Add();
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "addressee") Then
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					String,
					XDTORow.addressee,
					"Addressee");
			EndIf;
			String.ThisIsSubstitute = XDTORow.isDeputy;
		EndDo;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOData, "actualPerformers") Then
		For Each XDTORow In XDTOData.actualPerformers Do
			String = ActualPerformers.Add();
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "actualPerformer") Then
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					String,
					XDTORow.actualPerformer,
					"Employee");
			EndIf;
			String.Performer = XDTORow.performerPresentation;
		EndDo;
	EndIf;
	
	ThereAreAddressees = TaskRecipients.Count() > 1;
	ThereIsFactPerformers = ActualPerformers.Count() > 1;
	Items.AddresseesGroup.Visible = ThereAreAddressees;
	Items.GroupActualArtist.Visible = ThereIsFactPerformers;
	
	If ThereAreAddressees And ThereIsFactPerformers Then
		Title = NStr("vi = 'Chọn người thực hiện thực tế và nhân viên đang thực hiện nhiệm vụ';
					|ru = 'Выбор фактического исполнителя и сотрудника, за которого выполняется задача';
					|en = 'Select an actual assignee and an employee whose task is to be performed'; fa = 'Select an actual assignee and an employee whose task is to be performed';
					|it = 'Выбор фактического исполнителя и сотрудника, за которого выполняется задача';
					|pl = 'Select an actual assignee and an employee whose task is to be performed';
					|tr = 'Görevi asıl yerine getirenin ve görevin yerine getirildiği çalışanın seçimi'");
		SetFormAssignmentKey("PlanFact");
	ElsIf ThereAreAddressees Then
		Title = NStr("vi = 'Chọn nhân viên thực hiện nhiệm vụ';
					|ru = 'Выбор сотрудника, за которого выполняется задача';
					|en = 'Select an employee whose task is to be performed'; fa = 'Select an employee whose task is to be performed';
					|it = 'Выбор сотрудника, за которого выполняется задача';
					|pl = 'Select an employee whose task is to be performed';
					|tr = 'Görevin yerine getirildiği çalışanın seçimi'");
		SetFormAssignmentKey("Plan");
		Items.ExplanationAddressees.Title = NStr("vi = 'Hãy chỉ ra nhân viên:';
												|ru = 'Укажите сотрудника:';
												|en = 'Select an employee:'; fa = 'Select an employee:';
												|it = 'Укажите сотрудника:';
												|pl = 'Select an employee:';
												|tr = 'Çalışanı belirtin:'");
	Else
		Title = NStr("vi = 'Chọn người thực hiện nhiệm vụ thực tế';
					|ru = 'Выбор фактического исполнителя задачи';
					|en = 'Select an actual task assignee'; fa = 'Select an actual task assignee';
					|it = 'Выбор фактического исполнителя задачи';
					|pl = 'Select an actual task assignee';
					|tr = 'Görevi fiilen yerine getiren atananın seçimi'");
		SetFormAssignmentKey("Real");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TaskRecipientsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Select(Undefined);
	
EndProcedure

&AtClient
Procedure ActualPerformerSelection(Item, RowSelected, Field, StandardProcessing)
	
	Select(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("Addressee", Undefined);
	ReturnStructure.Insert("ThisIsSubstitute", False);
	ReturnStructure.Insert("Employee", Undefined);
	
	If ThereAreAddressees Then
		CurrentRecipients = Items.TaskRecipients.CurrentData;
		If CurrentRecipients = Undefined Then
			Return;
		EndIf;
		
		ReturnStructure.Insert("Addressee", ReferenceObjectDataDM(CurrentRecipients, "Addressee"));
		ReturnStructure.Insert("ThisIsSubstitute", CurrentRecipients.ThisIsSubstitute);
		
	ElsIf TaskRecipients.Count() > 0 And ValueIsFilled(TaskRecipients[0].AddresseeID) Then
		ReturnStructure.Insert("Addressee", ReferenceObjectDataDM(TaskRecipients[0], "Addressee"));
		ReturnStructure.Insert("ThisIsSubstitute", TaskRecipients[0].ThisIsSubstitute);
		
	EndIf;
	
	If ThereIsFactPerformers Then
		CurrentPerformer = Items.ActualPerformer.CurrentData;
		If CurrentPerformer = Undefined Then
			Return;
		EndIf;
		
		If ValueIsFilled(CurrentPerformer.EmployeeID) Then
			ReturnStructure.Insert("Employee", ReferenceObjectDataDM(CurrentPerformer, "Employee"));
		EndIf;
		
	ElsIf ValueIsFilled(ActualPerformers[0].EmployeeID) Then
		ReturnStructure.Insert("Employee", ReferenceObjectDataDM(ActualPerformers[0], "Employee"));
		
	EndIf;
	
	If Not ValueIsFilled(ReturnStructure.Employee) Then
		ReturnStructure.Insert("Employee", ReturnStructure.Addressee);
	EndIf;
	
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function ReferenceObjectDataDM(String, Var_AttributeName)
	
	Return IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		String[Var_AttributeName + "ID"],
		String[Var_AttributeName + "Type"],
		String[Var_AttributeName]);
	
EndFunction

&AtServer
Procedure SetFormAssignmentKey(Var_Key)
	
	PurposeUseKey = Var_Key;
	WindowOptionsKey = Var_Key;
	
EndProcedure

#EndRegion