
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Partner = Parameters.Partner;
	
	Parameters.Property("Organization", Organization);
	Parameters.Property("Counterparty",  Counterparty);
	
	FilteringByAgreementIsAvailable = Parameters.Property("Contract", Contract);
	FilteringByPartnersIsAvailable = GetFunctionalOption("UsePartnersAndCounterparties");
	
	DrillDownByOrders = Parameters.DrillDownByOrders;
	If ValueIsFilled(Contract) Then
		TypeOfTranscriptForPartnersContracts = 4;
	ElsIf Parameters.DrillDownByContracts Then
		TypeOfTranscriptForPartnersContracts = 3;
	ElsIf ValueIsFilled(Partner) Then
		TypeOfTranscriptForPartnersContracts = 2;
	ElsIf Parameters.DrillDownByPartners Then
		TypeOfTranscriptForPartnersContracts = 1;
	Else
		TypeOfTranscriptForPartnersContracts = 0;
	EndIf; 
	
	Items.Contract.Visible	 = FilteringByAgreementIsAvailable;
	Items.Contract.Enabled = TypeOfTranscriptForPartnersContracts = 4;
	Items.Partner.Enabled = TypeOfTranscriptForPartnersContracts = 2;
	
	Items.TypeOfTranscriptForPartnersContracts4.Visible = FilteringByAgreementIsAvailable;
	
	Items.TypeOfTranscriptForPartnersContracts1.Visible = FilteringByPartnersIsAvailable;
	Items.TypeOfTranscriptForPartnersContracts2.Visible = FilteringByPartnersIsAvailable;
	Items.Partner.Visible                             = FilteringByPartnersIsAvailable;
	
	If Not FilteringByPartnersIsAvailable Then
		Items.GroupDetailingMutualSettlements.Title = NStr("vi = 'Diễn giải hạch toán theo hợp đồng';
															|ru = 'Расшифровка расчетов по договорам';
															|en = 'Drill-down AR/AP under contracts'; fa = 'Drill-down AR/AP under contracts';
															|it = 'Расшифровка расчетов по договорам';
															|pl = 'Szczegóły rozliczeń wg umów';
															|tr = 'Sözleşme ödemelerinin dökümü'");
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TypeOfTranscriptForPartnersContractsWhenChanged(Item)
	
	Items.Partner.Enabled = TypeOfTranscriptForPartnersContracts = 2;
	Items.Contract.Enabled = TypeOfTranscriptForPartnersContracts = 4;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	Cancel = False;
	
	ClearMessages();
	
	If TypeOfTranscriptForPartnersContracts = 2 Then
		If Partner.IsEmpty() Then
			Text = NStr("vi = 'Chưa điền trường ""Lọc theo bạn hàng""';
						|ru = 'Поле ""Фильтр по партнеру"" не заполнено';
						|en = '""Filter by partner"" is required'; fa = '""Filter by partner"" is required';
						|it = 'Поле ""Фильтр по партнеру"" не заполнено';
						|pl = 'Pole ""Filtr według partnera"" nie jest wypełnione';
						|tr = '""İş ortağına göre filtre"" alanı doldurulmamış'");
			CommonClient.MessageToUser(
				Text,
				,
				"Partner",
				,
				Cancel);
		EndIf; 
	Else		
		Partner = PredefinedValue("Catalog.Partners.EmptyRef");
	EndIf; 
	
	If TypeOfTranscriptForPartnersContracts = 4 Then
		If Contract.IsEmpty() Then
			Text = NStr("vi = 'Chưa điền trường ""Lọc theo hợp đồng""';
						|ru = 'Поле ""Фильтр по договору"" не заполнено';
						|en = '""Filter by contract"" is required'; fa = '""Filter by contract"" is required';
						|it = 'Поле ""Фильтр по договору"" не заполнено';
						|pl = 'Pole ""Filtr według umowy"" nie jest wypełnione';
						|tr = '""Sözleşmeye göre filtre"" alanı doldurulmamış'");
			CommonClient.MessageToUser(
				Text,
				,
				"Contract",
				,
				Cancel);
		EndIf; 
	Else		
		Contract = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
	EndIf;
	
	If Not Cancel Then
		
		DrillDownByPartners = TypeOfTranscriptForPartnersContracts = 1;
		DrillDownByContracts = TypeOfTranscriptForPartnersContracts = 3;
		
		ReturnStructure = New Structure;
		ReturnStructure.Insert("DrillDownByOrders", DrillDownByOrders);
		ReturnStructure.Insert("DrillDownByPartners", DrillDownByPartners);
		ReturnStructure.Insert("DrillDownByContracts", DrillDownByContracts);
		ReturnStructure.Insert("Partner", Partner);
		ReturnStructure.Insert("Contract", Contract);
		
		Close(ReturnStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
