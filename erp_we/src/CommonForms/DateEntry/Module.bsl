
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	NewDate = Parameters.Date;
	BeginOfPeriod = Parameters.BeginOfPeriod;
	EndOfPeriod = Parameters.EndOfPeriod;
	
	If Parameters.DatePart = DateFractions.Date Then
		DateFormat = "DLF=D;";
	Else
		DateFormat = "DLF=DT;";
	EndIf;

	Items.NewDate.Format = DateFormat;
	Items.NewDate.EditFormat = DateFormat;
	
	If ValueIsFilled(Parameters.ToolTip) Then
		Title = Parameters.ToolTip;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If BeginOfPeriod <> '000101010000'
		And EndOfPeriod <> '000101010000' Then
			
		If NewDate < BeginOfPeriod
			Or NewDate > EndOfPeriod Then
				
			MessageText = StrTemplate(
				NStr("vi = 'Ngày phải nằm trong khoảng từ %1 đến %2';
					|ru = 'Дата должна быть в интервале с %1 по %2';
					|en = 'The date must be in the range from %1 to %2'; fa = 'The date must be in the range from %1 to %2';
					|it = 'La data deve essere nell''intervallo tra %1 e %2';
					|pl = 'Data powinna być w przedziale od %1 do %2';
					|tr = 'Tarih %1 tarihinden %2 kadar olan aralıkta olmalı'"), 
				Format(BeginOfPeriod, DateFormat),
				Format(EndOfPeriod, DateFormat));
			
			Common.MessageToUser(MessageText,,,, Cancel);
			
		EndIf;
		
	ElsIf BeginOfPeriod <> '000101010000' 
		And NewDate < BeginOfPeriod Then
			
		MessageText = StrTemplate(
			NStr("vi = 'Ngày không được sớm hơn %1';
				|ru = 'Дата должна быть не раньше %1';
				|en = 'The date must be not earlier than %1'; fa = 'The date must be not earlier than %1';
				|it = 'La data non deve essere precedente a %1';
				|pl = 'Data powinna być nie wcześniejsza niż %1';
				|tr = 'Tarih %1 erken olmamalı'"), 
			Format(BeginOfPeriod, DateFormat));
		
		Common.MessageToUser(MessageText,,,, Cancel);
			
	ElsIf EndOfPeriod <> '000101010000' 
		And NewDate > EndOfPeriod Then
			
		MessageText = StrTemplate(
			NStr("vi = 'Ngày không được muộn hơn %1';
				|ru = 'Дата должна быть не позже %1';
				|en = 'The date must be not later than %1'; fa = 'The date must be not later than %1';
				|it = 'La data non deve essere successiva a %1';
				|pl = 'Data powinna być nie późniejsza niż %1';
				|tr = 'Tarih %1 geç olmamalı'"), 
			Format(EndOfPeriod, DateFormat));
		
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteInput(Command)
	
	If CheckFilling() Then
		Close(NewDate);
	EndIf;	

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
