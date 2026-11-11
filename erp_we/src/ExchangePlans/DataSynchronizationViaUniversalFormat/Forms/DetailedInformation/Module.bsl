#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Template = ExchangePlans.DataSynchronizationViaUniversalFormat.GetTemplate("DetailedInformation");
	HTMLDocumentField = Template.GetText();
	
	Title = NStr("vi = 'Thông tin về đồng bộ dữ liệu';
				|ru = 'Информация о синхронизации данных';
				|en = 'Data synchronization information'; fa = 'Data synchronization information';
				|it = 'Informazioni di sincronizzazione dati';
				|pl = 'Informacje o synchronizacji danych';
				|tr = 'Veri senkronizasyonu ile ilgili bilgi'");

EndProcedure

#EndRegion