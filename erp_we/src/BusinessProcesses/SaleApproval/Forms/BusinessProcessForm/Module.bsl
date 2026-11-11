
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	SetConditionalAppearance();
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	CalculateStatus();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If CurrentObject.Started Then
		CalculateStatus();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApprovalDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StateOverdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(NStr("vi = 'Đã thống nhất';
						|ru = 'Согласовано';
						|en = 'Approved'; fa = 'تأییدشده';
						|it = 'Concordato';
						|pl = 'Uzgodniono';
						|tr = 'Onaylandı'"));
	ValueList.Add(NStr("vi = 'Không thống nhất';
						|ru = 'Не согласовано';
						|en = 'Not approved'; fa = 'تأییدنشده';
						|it = 'Non concordato';
						|pl = 'Nie uzgodniono';
						|tr = 'Onaylanmadı'"));
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("TextColor", WebColors.RosyBrown);

EndProcedure

#Region Other

&AtServer
Procedure CalculateStatus()
	
	If Object.Started Then
		If Object.Completed Then
			If Object.ApprovalResult = Enums.ApprovalResults.Approved Then
				State = NStr("vi = 'Đã thống nhất';
							|ru = 'Согласовано';
							|en = 'Approved'; fa = 'تأییدشده';
							|it = 'Concordato';
							|pl = 'Uzgodniono';
							|tr = 'Onaylandı'");
			ElsIf Object.ApprovalResult = Enums.ApprovalResults.NotApproved Then
				State = NStr("vi = 'Không thống nhất';
							|ru = 'Не согласовано';
							|en = 'Not approved'; fa = 'تأییدنشده';
							|it = 'Non concordato';
							|pl = 'Nie uzgodniono';
							|tr = 'Onaylanmadı'");
			EndIf;
		Else
			State = NStr("vi = 'Trong quá trình thống nhất';
						|ru = 'В процессе согласования';
						|en = 'Pending approval'; fa = 'در انتظار تأیید';
						|it = 'Nel processo degli accordi';
						|pl = 'W trakcie uzgadniania';
						|tr = 'Onay sürecinde'");
		EndIf;
	Else
		State = "";
	EndIf;
	
	If Object.Started And Not Object.Completed And ValueIsFilled(Object.ApprovalDate) And Object.ApprovalDate < BegOfDay(CurrentSessionDate()) Then
		StateOverdue = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
