#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not AdditionalProperties.Property("SyncingKeyWithValue")
		And Not DeletionMark Then

		// The document is not used independently.

		Cancel = True;
		ErrorText = NStr("vi = 'Chỉ có thể ghi lại đối tượng này từ cơ chế bổ trợ';
						|ru = 'Запись этого объекта возможна только из служебных механизмов';
						|en = 'Recording of this object is possible only from the internal application algorithms'; fa = 'Recording of this object is possible only from the internal application algorithms';
						|it = 'Registrazione di questo oggetto è possibile solo dai meccanismi di servizio';
						|pl = 'Zapis tego obiektu jest możliwy tylko z mechanizmów serwisowych';
						|tr = 'Bu nesne yalnızca servis mekanizmalarından yazılabilir'");
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			,
			,
			Cancel);
		
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	GoodsReceiptSchedule.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.InventoryAndDemands AS GoodsReceiptSchedule
	|WHERE
	|	GoodsReceiptSchedule.Recorder = &Recorder";
	
	Query.SetParameter("Recorder", Ref);
	
	If Not Query.Execute().IsEmpty() Then
		
		ExceptionText = NStr("vi = 'Theo chứng từ %Document% có bản ghi kết chuyển trong biểu ghi ""Vật tư và nhu cầu"". Không thể xóa chứng từ.';
							|ru = 'По документу %Document% есть движения в регистре ""Запасы и потребности"". Удаление документа невозможно.';
							|en = 'There are records in the ""Inventory and demands"" register for the %Document% document. Cannot delete the document.'; fa = 'There are records in the ""Inventory and demands"" register for the %Document% document. Cannot delete the document.';
							|it = 'Per il documento %Document% vi sono movimenti nel registro ""Scorte e consumi"". Impossibile eliminare il documento.';
							|pl = 'Według dokumentu %Document% są przepływy w rejestrze ""Zapasy i zapotrzebowanie"". Usunięcie dokumentu jest niemożliwe.';
							|tr = '%Document% belgesi üzerinde ""Stok ve talepler"" kaydında değişiklikler var. Belge silinemez.'");
		ExceptionText = StrReplace(ExceptionText, "%Document%", Ref);
		
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf