#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		
		Try
			Block = New DataLock();
			LockItem = Block.Add("Catalog.Companies");
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Selection = Catalogs.Companies.Select();
			While Selection.Next() Do
				OrganizationObject = Selection.Ref.GetObject();
				OrganizationObject.RegistrationCountry = Value;
				OrganizationObject.DataExchange.Load = True;
				OrganizationObject.Write();
			EndDo;
		Except
			Raise;
		EndTry;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndIf