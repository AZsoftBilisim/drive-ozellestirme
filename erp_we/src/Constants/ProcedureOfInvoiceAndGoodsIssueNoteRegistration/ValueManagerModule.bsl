 //@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst Then
		
		UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
		If UsedDelivery25
			And GoodsDelivery.ThereAreWarehousesWithKitsForPostDelivery(True) Then
			
			MessageText = NStr("ru = 'Включение опции ""Сначала заказы и накладные, затем ордера"" возможно при отсутствии в системе ордерных складов с настройкой ""Сборка осуществляется после планирования рейса"".';
								|vi = 'You can enable the ""Orders and invoices first, then goods issues"" option if there is no warehouse management with the ""Picking after trip planning"" setting in the system.';
								|en = 'You can enable the ""Orders and invoices first, then goods issues"" option if there is no warehouse management with the ""Picking after trip planning"" setting in the system.'; fa = 'You can enable the ""Orders and invoices first, then goods issues"" option if there is no warehouse management with the ""Picking after trip planning"" setting in the system.';
								|it = 'You can enable the ""Orders and invoices first, then goods issues"" option if there is no warehouse management with the ""Picking after trip planning"" setting in the system.';
								|pl = 'You can enable the ""Orders and invoices first, then goods issues"" option if there is no warehouse management with the ""Picking after trip planning"" setting in the system.';
								|tr = '""Önce siparişler ve irsaliyeler, ardından emirler"" seçeneğinin etkinleştirilmesi, sistemde ""Toplama, sefer planlamasından sonra gerçekleştirilir"" ayarına sahip emir ambarlarının bulunmaması durumunda mümkündür.'");
			Common.MessageToUser(MessageText,,,, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf