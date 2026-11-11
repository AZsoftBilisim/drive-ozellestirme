
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)                                            
	
	EquipmentManagerClient.SetConnectionModeOfComputerInformationExtension(True);
	EquipmentManagerClient.UpdateClientWorkplace();
	
	CurrentWorkplace = EquipmentManagerClient.CustomerWorkplace();
	List.Parameters.SetParameterValue("CurrentWorkplace", CurrentWorkplace); 
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	ClientID = EquipmentManagerClient.ClientIDForWorkplace();
	Workplace = GetWorkplaceByClientID(ClientID);
	
	If Not Workplace = Undefined Then
		
		Cancel = True;
			                  
		Text = NStr("vi = 'Không cần tạo mới chỗ làm việc. 
					|Đối với tên định danh này của khách hàng, đã tạo chỗ làm việc.
					|Mở chỗ làm việc có sẵn?';
					|ru = 'Создание нового рабочего места не требуется. 
					|Для данного идентификатора клиента оно уже создано.
					|Открыть существующее рабочее место?';
					|en = 'It is not required to create a new workplace.
					|It is already created for this client ID.
					|Open the existing workplace?'; fa = 'It is not required to create a new workplace.
					|It is already created for this client ID.
					|Open the existing workplace?';
					|it = 'Non è necessario creare un nuovo posto di lavoro.
					|Ne è già stato creato uno per questo ID cliente
					|.Aprire il posto di lavoro esistente?';
					|pl = 'Tworzenie nowego miejsca pracy nie jest konieczne. 
					|Dla danego identyfikatora klienta zostało ono już utworzone.
					|Otworzyć istniejące miejsce pracy?';
					|tr = 'Yeni çalışma alanı oluşturmak zorunlu değildir.
					|Bu istemci tanımlayıcısı için çalışma alanı zaten oluşturuldu.
					|Mevcut çalışma alanlarından biri açılsın mı?'");
		Notification = New CallbackDescription("ListBeforeAddRowCompletion", ThisObject, Workplace);
		ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure  

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "ChangedCurSessionWorkplace" Then
		CurrentWorkplace = EquipmentManagerClient.CustomerWorkplace();
		List.Parameters.SetParameterValue("CurrentWorkplace", CurrentWorkplace); 
		Items.List.Refresh();
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ListBeforeAddRowCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes And Not IsBlankString(Var_Parameters) Then
		ShowValue(, Var_Parameters);
	EndIf;  
	
EndProcedure 

&AtServer
Function GetWorkplaceByClientID(Id)
	
	Result = Undefined;
	
	Query = New Query("
	|SELECT
	|    Workplaces.Ref
	|FROM
	|    Catalog.Workplaces AS Workplaces
	|WHERE
	|    Workplaces.Code = &Id");
	
	Query.SetParameter("Id", Id);
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Result = SelectionDetailRecords.Ref;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion