#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsNew() Then
		RecordsInWarehouseRegisters = True;
	EndIf;
	
	ControlOnlyStock =
		Not LineOfBusiness.IsEmpty() And Not ValueIsFilled(OrderDocument)
			And Common.ObjectAttributeValue(LineOfBusiness,
				"ExcessOfAssignedGoodsAndLaborDemandIsAllowed");
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Raise NStr("vi = 'Không thể sao chép';
				|ru = 'Копирование недоступно';
				|en = 'Copying is not available'; fa = 'Copying is not available';
				|it = 'Copiatura non disponibile';
				|pl = 'Kopiowanie jest niedostępne';
				|tr = 'Kopyalama mevcut değil'");;
	
EndProcedure

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
#EndIf