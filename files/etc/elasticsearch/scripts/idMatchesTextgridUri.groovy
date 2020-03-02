def idp = doc['_uid'].value;
def urip = _source['textgridUri'];
if( ! (urip instanceof String) ) {
  return true;
}

def id = idp.tokenize('#')[1];
def uri = urip.tokenize(':')[1];
return ! id.equals(uri);

