#Region Internal

Function LogicalStorageManagers() Export
	
	AllLogicalStorageManagers = New Map;
	
	DataTransferIntegration.LogicalStorageManagers(AllLogicalStorageManagers);
	DataTransferOverridable.LogicalStorageManagers(AllLogicalStorageManagers);
	
	Return New FixedMap(AllLogicalStorageManagers);
	
EndFunction

Function PhysicalStorageManagers() Export
	
	AllPhysicalStorageManagers = New Map;
	
	DataTransferIntegration.PhysicalStorageManagers(AllPhysicalStorageManagers);
	DataTransferOverridable.PhysicalStorageManagers(AllPhysicalStorageManagers);
	
	Return New FixedMap(AllPhysicalStorageManagers);
	
EndFunction

Function Join(URIStructure, User, Password, Timeout) Export
	
	SecureConnection = ?(URIStructure.Schema = "https", CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates), Undefined);
	Port = ?(ValueIsFilled(URIStructure.Port), Number(URIStructure.Port), ?(SecureConnection = Undefined, 80, 443));
	Proxy = Undefined;
	
	DataTransferIntegration.OnGetProxy(Proxy, URIStructure);
	
	Return New HTTPConnection(URIStructure.Host, Port, User, Password, Proxy, Timeout, SecureConnection);
	
EndFunction

#EndRegion
