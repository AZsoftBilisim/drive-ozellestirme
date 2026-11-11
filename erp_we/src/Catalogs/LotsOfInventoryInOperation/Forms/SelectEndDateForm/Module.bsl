
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	SetDynamicListProperties();
	
	FilterDate = Parameters.Period;
	
	CloseOnChoice = True;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	List.Parameters.SetParameterValue("Period", BegOfMonth(FilterDate));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CompleteSelection();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandCompleteSelection(Command)
	
	CompleteSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetDynamicListProperties()
	
	List.Parameters.SetParameterValue("Period", BegOfMonth(Parameters.Period));
	List.Parameters.SetParameterValue("Organization", Parameters.Organization);
	List.Parameters.SetParameterValue("Products", Parameters.Products);
	List.Parameters.SetParameterValue("Characteristic", Parameters.Characteristic);
	List.Parameters.SetParameterValue("Series", Parameters.Series);
	List.Parameters.SetParameterValue("LineOfBusiness", Parameters.LineOfBusiness);

EndProcedure

&AtClient
Procedure CompleteSelection()
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Cần chọn ngày hoàn tất vận hành';
							|ru = 'Необходимо выбрать дату завершения эксплуатации';
							|en = 'Select the operation end date'; fa = 'Select the operation end date';
							|it = 'È necessario selezionare la data di completamento della lavorazione';
							|pl = 'Należy wybrać datę zakończenia eksploatacji';
							|tr = 'İşlem bitiş tarihi seçilmelidir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	NotifyChoice(CurrentData.CompletionDate_);
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_FilterDate" Then
		FilterDateOnChange(Items.FilterDate);
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
