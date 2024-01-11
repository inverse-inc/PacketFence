package models

import (
	"crypto"
	"html/template"
	"net"
	"net/http"
	"os"
	"reflect"
	"regexp"
	"time"

	"bytes"
	"crypto/dsa"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base64"
	"encoding/hex"
	"encoding/pem"
	"errors"
	"math/big"
	"strconv"
	"strings"

	"github.com/inverse-inc/scep/cryptoutil"
	"github.com/inverse-inc/scep/scep"
	"github.com/knq/pemutil"

	"context"
	"fmt"
	"io"

	"github.com/inverse-inc/go-utils/log"
	"github.com/inverse-inc/packetfence/go/caddy/pfpki/certutils"
	"github.com/inverse-inc/packetfence/go/caddy/pfpki/cloud"
	"github.com/inverse-inc/packetfence/go/caddy/pfpki/sql"
	"github.com/inverse-inc/packetfence/go/caddy/pfpki/types"
	_ "gorm.io/driver/mysql"
	"gorm.io/gorm"
	pkcs12 "software.sslmate.com/src/go-pkcs12"

	"github.com/inverse-inc/packetfence/go/pfconfigdriver"
	"golang.org/x/crypto/ocsp"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
	"golang.org/x/text/message/catalog"
	gomail "gopkg.in/gomail.v2"
	yaml "gopkg.in/yaml.v2"
)

type (
	// CA struct
	CA struct {
		ID                   uint                    `gorm:"primarykey"`
		CreatedAt            time.Time               `json:"-"`
		UpdatedAt            time.Time               `json:"-"`
		DeletedAt            gorm.DeletedAt          `json:"-" gorm:"index"`
		DB                   gorm.DB                 `json:"-" gorm:"-"`
		Ctx                  context.Context         `json:"-" gorm:"-"`
		Cn                   string                  `json:"cn,omitempty" gorm:"UNIQUE"`
		Mail                 string                  `json:"mail,omitempty" gorm:"INDEX:mail"`
		Organisation         string                  `json:"organisation,omitempty" gorm:"INDEX:organisation"`
		OrganisationalUnit   string                  `json:"organisational_unit,omitempty"`
		Country              string                  `json:"country,omitempty"`
		State                string                  `json:"state,omitempty"`
		Locality             string                  `json:"locality,omitempty"`
		StreetAddress        string                  `json:"street_address,omitempty"`
		PostalCode           string                  `json:"postal_code,omitempty"`
		KeyType              *types.Type             `json:"key_type,omitempty,string"`
		KeySize              int                     `json:"key_size,omitempty,string"`
		Digest               x509.SignatureAlgorithm `json:"digest,omitempty,string"`
		KeyUsage             *string                 `json:"key_usage,omitempty"`
		ExtendedKeyUsage     *string                 `json:"extended_key_usage,omitempty"`
		Days                 int                     `json:"days,omitempty,string"`
		Key                  string                  `json:"-" gorm:"type:longtext"`
		Cert                 string                  `json:"cert,omitempty" gorm:"type:longtext"`
		IssuerKeyHash        string                  `json:"issuer_key_hash,omitempty" gorm:"UNIQUE_INDEX"`
		IssuerNameHash       string                  `json:"issuer_name_hash,omitempty" gorm:"UNIQUE_INDEX"`
		OCSPUrl              string                  `json:"ocsp_url,omitempty"`
		SCEPAssociateProfile string                  `gorm:"-"`
		Cloud                cloud.Cloud             `gorm:"-"`
		SerialNumber         int                     `json:"-"`
	}

	// Profile struct
	Profile struct {
		ID                    uint                    `gorm:"primarykey"`
		CreatedAt             time.Time               `json:"-"`
		UpdatedAt             time.Time               `json:"-"`
		DeletedAt             gorm.DeletedAt          `json:"-" gorm:"index"`
		DB                    gorm.DB                 `json:"-" gorm:"-"`
		Ctx                   context.Context         `json:"-" gorm:"-"`
		Name                  string                  `json:"name" gorm:"UNIQUE"`
		Mail                  string                  `json:"mail,omitempty" gorm:"INDEX:mail"`
		Organisation          string                  `json:"organisation,omitempty" gorm:"INDEX:organisation"`
		OrganisationalUnit    string                  `json:"organisational_unit,omitempty"`
		Country               string                  `json:"country,omitempty"`
		State                 string                  `json:"state,omitempty"`
		Locality              string                  `json:"locality,omitempty"`
		StreetAddress         string                  `json:"street_address,omitempty"`
		PostalCode            string                  `json:"postal_code,omitempty"`
		Ca                    CA                      `json:"-"`
		CaID                  uint                    `json:"ca_id,omitempty,string" gorm:"INDEX:ca_id"`
		CaName                string                  `json:"ca_name,omitempty" gorm:"INDEX:ca_name"`
		Validity              int                     `json:"validity,omitempty,string"`
		KeyType               *types.Type             `json:"key_type,omitempty,string"`
		KeySize               int                     `json:"key_size,omitempty,string"`
		Digest                x509.SignatureAlgorithm `json:"digest,omitempty,string"`
		KeyUsage              *string                 `json:"key_usage,omitempty"`
		ExtendedKeyUsage      *string                 `json:"extended_key_usage,omitempty"`
		OCSPUrl               string                  `json:"ocsp_url,omitempty"`
		P12MailPassword       int                     `json:"p12_mail_password,omitempty,string"`
		P12MailSubject        string                  `json:"p12_mail_subject,omitempty"`
		P12MailFrom           string                  `json:"p12_mail_from,omitempty"`
		P12MailHeader         string                  `json:"p12_mail_header,omitempty"`
		P12MailFooter         string                  `json:"p12_mail_footer,omitempty"`
		SCEPEnabled           int                     `json:"scep_enabled,omitempty"`
		SCEPChallengePassword string                  `json:"scep_challenge_password,omitempty"`
		SCEPDaysBeforeRenewal int                     `json:"scep_days_before_renewal,string" gorm:"default:14"`
		DaysBeforeRenewal     int                     `json:"days_before_renewal,string" gorm:"default:14"`
		RenewalMail           int                     `json:"renewal_mail,omitempty,string" gorm:"default:1"`
		DaysBeforeRenewalMail int                     `json:"days_before_renewal_mail,string" gorm:"default:14"`
		RenewalMailSubject    string                  `json:"renewal_mail_subject,omitempty" gorm:"default:Certificate expiration"`
		RenewalMailFrom       string                  `json:"renewal_mail_from,omitempty"`
		RenewalMailHeader     string                  `json:"renewal_mail_header,omitempty"`
		RenewalMailFooter     string                  `json:"renewal_mail_footer,omitempty"`
		RevokedValidUntil     int                     `json:"revoked_valid_until,omitempty,string" gorm:"default:14"`
		CloudEnabled          int                     `json:"cloud_enabled,omitempty"`
		CloudService          string                  `json:"cloud_service,omitempty"`
		ScepServerEnabled     int                     `json:"scep_server_enabled,omitempty" gorm:"default:0"`
		ScepServer            SCEPServer              `json:"-"`
		ScepServerID          uint                    `json:"scep_server_id,omitempty,string" gorm:"INDEX:scep_server_id"`
	}

	// Cert struct
	Cert struct {
		ID                 uint            `gorm:"primarykey"`
		CreatedAt          time.Time       `json:"-"`
		UpdatedAt          time.Time       `json:"-"`
		DeletedAt          gorm.DeletedAt  `json:"-" gorm:"index"`
		DB                 gorm.DB         `json:"-" gorm:"-"`
		Ctx                context.Context `json:"-" gorm:"-"`
		Cn                 string          `json:"cn,omitempty"`
		Mail               string          `json:"mail,omitempty" gorm:"INDEX:mail"`
		Ca                 CA              `json:"-"`
		CaID               uint            `json:"ca_id,omitempty" gorm:"INDEX:ca_id"`
		CaName             string          `json:"ca_name,omitempty" gorm:"INDEX:ca_name"`
		StreetAddress      string          `json:"street_address,omitempty"`
		Organisation       string          `json:"organisation,omitempty" gorm:"INDEX:organisation"`
		OrganisationalUnit string          `json:"organisational_unit,omitempty"`
		Country            string          `json:"country,omitempty"`
		State              string          `json:"state,omitempty"`
		Locality           string          `json:"locality,omitempty"`
		PostalCode         string          `json:"postal_code,omitempty"`
		Key                string          `json:"-" gorm:"type:longtext"`
		Cert               string          `json:"cert,omitempty" gorm:"type:longtext"`
		Profile            Profile         `json:"-"`
		ProfileID          uint            `json:"profile_id,omitempty,string" gorm:"INDEX:profile_id"`
		ProfileName        string          `json:"profile_name,omitempty" gorm:"INDEX:profile_name"`
		ValidUntil         time.Time       `json:"valid_until,omitempty" gorm:"INDEX:valid_until" gorm:"type:time"`
		NotBefore          time.Time       `json:"not_before,omitempty" gorm:"INDEX:not_before" gorm:"type:time"`
		Date               time.Time       `json:"date,omitempty" gorm:"default:CURRENT_TIMESTAMP"`
		SerialNumber       string          `json:"serial_number,omitempty"`
		DNSNames           string          `json:"dns_names,omitempty"`
		IPAddresses        string          `json:"ip_addresses,omitempty"`
		Scep               *bool           `json:"scep,omitempty" gorm:"default:false"`
		Csr                *bool           `json:"csr,omitempty" gorm:"default:false"`
		Alert              *bool           `json:"alert,omitempty" gorm:"default:false"`
		Subject            string          `json:"-" gorm:"UNIQUE"`
	}

	// CSR struct
	CSR struct {
		DB  gorm.DB         `gorm:"-"`
		Ctx context.Context `gorm:"-"`
		Csr string          `json:"csr"`
	}

	// RevokedCert struct
	RevokedCert struct {
		ID                 uint            `gorm:"primarykey"`
		CreatedAt          time.Time       `json:"-"`
		UpdatedAt          time.Time       `json:"-"`
		DeletedAt          gorm.DeletedAt  `json:"-" gorm:"index"`
		DB                 gorm.DB         `gorm:"-"`
		Ctx                context.Context `gorm:"-"`
		Cn                 string          `json:"cn,omitempty" gorm:"INDEX:cn"`
		Mail               string          `json:"mail,omitempty" gorm:"INDEX:mail"`
		Ca                 CA              `json:"-"`
		CaID               uint            `json:"ca_id,omitempty" gorm:"INDEX:ca_id"`
		CaName             string          `json:"ca_name,omitempty" gorm:"INDEX:ca_name"`
		StreetAddress      string          `json:"street_address,omitempty"`
		Organisation       string          `json:"organisation,omitempty" gorm:"INDEX:organisation"`
		OrganisationalUnit string          `json:"organisational_unit,omitempty"`
		Country            string          `json:"country,omitempty"`
		State              string          `json:"state,omitempty"`
		Locality           string          `json:"locality,omitempty"`
		PostalCode         string          `json:"postal_code,omitempty"`
		Key                string          `json:"-" gorm:"type:longtext"`
		Cert               string          `json:"cert,omitempty" gorm:"type:longtext"`
		Profile            Profile         `json:"-"`
		ProfileID          uint            `json:"profile_id,omitempty" gorm:"INDEX:profile_id"`
		ProfileName        string          `json:"profile_name,omitempty" gorm:"INDEX:profile_name"`
		ValidUntil         time.Time       `json:"valid_until,omitempty" gorm:"INDEX:valid_until" gorm:"type:time"`
		NotBefore          time.Time       `json:"not_before,omitempty" gorm:"INDEX:not_before" gorm:"type:time"`
		Date               time.Time       `json:"date,omitempty" gorm:"default:CURRENT_TIMESTAMP"`
		SerialNumber       string          `json:"serial_number,omitempty"`
		DNSNames           string          `json:"dns_names,omitempty"`
		IPAddresses        string          `json:"ip_addresses,omitempty"`
		Revoked            time.Time       `json:"revoked,omitempty" gorm:"INDEX:revoked"`
		CRLReason          int             `json:"crl_reason,omitempty" gorm:"INDEX:crl_reason"`
		Subject            string          `json:"-"`
	}
	// SCEP struct
	SCEPServer struct {
		ID           uint            `gorm:"primarykey"`
		CreatedAt    time.Time       `json:"-"`
		UpdatedAt    time.Time       `json:"-"`
		DeletedAt    gorm.DeletedAt  `json:"-" gorm:"index"`
		DB           gorm.DB         `json:"-" gorm:"-"`
		Ctx          context.Context `json:"-" gorm:"-"`
		Name         string          `json:"name,omitempty" gorm:"UNIQUE"`
		URL          string          `json:"url,omitempty""`
		SharedSecret string          `json:"shared_secret,omitempty"`
	}
)

type Tabler interface {
	TableName() string
}

// TableName overrides the table name used by CA to `pki_cas`
func (CA) TableName() string {
	return "pki_cas"
}

// TableName overrides the table name used by Profiles to `pki_profiles`
func (Profile) TableName() string {
	return "pki_profiles"
}

// TableName overrides the table name used by Cert to `pki_certs`
func (Cert) TableName() string {
	return "pki_certs"
}

// TableName overrides the table name used by Cert to `pki_revoked_certs`
func (RevokedCert) TableName() string {
	return "pki_revoked_certs"
}

// TableName overrides the table name used by SCEPServer to `pki_scep`
func (SCEPServer) TableName() string {
	return "pki_scep_servers"
}

const dbError = "A database error occured. See log for details."

// Digest Values:
// 0 UnknownSignatureAlgorithm
// 1 MD2WithRSA
// 2 MD5WithRSA
// 3 SHA1WithRSA
// 4 SHA256WithRSA
// 5 SHA384WithRSA
// 6 SHA512WithRSA
// 7 DSAWithSHA1
// 8 DSAWithSHA256
// 9 ECDSAWithSHA1
// 10 ECDSAWithSHA256
// 11 ECDSAWithSHA384
// 12 ECDSAWithSHA512
// 13 SHA256WithRSAPSS
// 14 SHA384WithRSAPSS
// 15 SHA512WithRSAPSS
// 16 PureEd25519

// KeyUsage Values:
// 1 KeyUsageDigitalSignature
// 2 KeyUsageContentCommitment
// 4 KeyUsageKeyEncipherment
// 8 KeyUsageDataEncipherment
// 16 KeyUsageKeyAgreement
// 32 KeyUsageCertSign
// 64 KeyUsageCRLSign
// 128 KeyUsageEncipherOnly
// 256 KeyUsageDecipherOnly

// ExtendedKeyUsage Values:
// 0 ExtKeyUsageAny
// 1 ExtKeyUsageServerAuth
// 2 ExtKeyUsageClientAuth
// 3 ExtKeyUsageCodeSigning
// 4 ExtKeyUsageEmailProtection
// 5 ExtKeyUsageIPSECEndSystem
// 6 ExtKeyUsageIPSECTunnel
// 7 ExtKeyUsageIPSECUser
// 8 ExtKeyUsageTimeStamping
// 9 ExtKeyUsageOCSPSigning
// 10 ExtKeyUsageMicrosoftServerGatedCrypto
// 11 ExtKeyUsageNetscapeServerGatedCrypto
// 12 ExtKeyUsageMicrosoftCommercialCodeSigning
// 13 ExtKeyUsageMicrosoftKernelCodeSigning

var successDBConnect = false

// NewCAModel create a CAModel
func NewCAModel(pfpki *types.Handler) *CA {
	CA := &CA{}

	CA.DB = *pfpki.DB
	CA.Ctx = *pfpki.Ctx

	return CA
}

// New create a new CA
func (c CA) New() (types.Info, error) {

	Information := types.Info{}

	keyOut, pub, key, err := certutils.GenerateKey(*c.KeyType, c.KeySize)

	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	skid, err := certutils.CalculateSKID(pub)
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	var cadb CA
	var newcadb []CA

	var SerialNumber *big.Int

	if CaDB := c.DB.Last(&cadb); CaDB.Error != nil {
		SerialNumber = big.NewInt(1)
	} else {
		SerialNumber = big.NewInt(int64(cadb.ID + 1))
	}

	Subject := c.MakeSubject()

	ca := &x509.Certificate{
		SerialNumber:          SerialNumber,
		Subject:               Subject,
		NotBefore:             time.Now(),
		NotAfter:              time.Now().AddDate(0, 0, c.Days),
		IsCA:                  true,
		SignatureAlgorithm:    c.Digest,
		ExtKeyUsage:           certutils.Extkeyusage(strings.Split(*c.ExtendedKeyUsage, "|")),
		KeyUsage:              x509.KeyUsage(certutils.Keyusage(strings.Split(*c.KeyUsage, "|"))),
		BasicConstraintsValid: true,
		EmailAddresses:        []string{c.Mail},
		SubjectKeyId:          skid,
		AuthorityKeyId:        skid,
	}

	if len(c.OCSPUrl) > 0 {
		ca.OCSPServer = []string{c.OCSPUrl}
	}

	var caBytes []byte

	switch *c.KeyType {
	case certutils.KEY_RSA:
		caBytes, err = x509.CreateCertificate(rand.Reader, ca, ca, pub, key.(*rsa.PrivateKey))
	case certutils.KEY_ECDSA:
		caBytes, err = x509.CreateCertificate(rand.Reader, ca, ca, pub, key.(*ecdsa.PrivateKey))
	case certutils.KEY_DSA:
		caBytes, err = x509.CreateCertificate(rand.Reader, ca, ca, pub, key.(*dsa.PrivateKey))
	}
	if err != nil {
		return Information, err
	}

	cert := new(bytes.Buffer)

	// Public key
	pem.Encode(cert, &pem.Block{Type: "CERTIFICATE", Bytes: caBytes})

	// Calculate the IssuerNameHash
	catls, err := tls.X509KeyPair([]byte(cert.String()), []byte(keyOut.String()))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	h := sha1.New()

	h.Write(cacert.RawIssuer)

	if err := c.DB.Create(&CA{Cn: c.Cn, Mail: c.Mail, Organisation: c.Organisation, OrganisationalUnit: c.OrganisationalUnit, Country: c.Country, State: c.State, Locality: c.Locality, StreetAddress: c.StreetAddress, PostalCode: c.PostalCode, KeyType: c.KeyType, KeySize: c.KeySize, Digest: c.Digest, KeyUsage: c.KeyUsage, ExtendedKeyUsage: c.ExtendedKeyUsage, Days: c.Days, Key: keyOut.String(), Cert: cert.String(), IssuerKeyHash: hex.EncodeToString(skid), IssuerNameHash: hex.EncodeToString(h.Sum(nil)), OCSPUrl: c.OCSPUrl, SerialNumber: 1}).Error; err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}

	c.DB.Select("id, cn, mail, organisation, organisational_unit, country, state, locality, street_address, postal_code, key_type, key_size, digest, key_usage, extended_key_usage, days, cert, ocsp_url").Where("cn = ?", c.Cn).First(&newcadb)
	Information.Entries = newcadb

	return Information, nil
}

func (c CA) MakeSubject() pkix.Name {
	var Subject pkix.Name
	Subject.CommonName = c.Cn

	if len(c.Organisation) > 0 {
		Subject.Organization = []string{c.Organisation}
	}

	if len(c.OrganisationalUnit) > 0 {
		Subject.OrganizationalUnit = []string{c.OrganisationalUnit}
	}

	if len(c.Country) > 0 {
		Subject.Country = []string{c.Country}
	}

	if len(c.State) > 0 {
		Subject.Province = []string{c.State}
	}

	if len(c.Locality) > 0 {
		Subject.Locality = []string{c.Locality}
	}

	if len(c.StreetAddress) > 0 {
		Subject.StreetAddress = []string{c.StreetAddress}
	}

	if len(c.PostalCode) > 0 {
		Subject.PostalCode = []string{c.PostalCode}
	}
	return Subject
}

// GetByID retreive the CA by id
func (c CA) GetByID(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var cadb []CA
	if val, ok := params["id"]; ok {
		allFields := strings.Join(sql.SqlFields(c)[:], ",")
		c.DB.Select(allFields).Where("`id` = ?", val).First(&cadb)
	}
	Information.Entries = cadb

	return Information, nil
}

// Fix calculate the IssuerKeyHash and IssuerNameHash
func (c CA) Fix() (types.Info, error) {
	Information := types.Info{}
	var cadb []CA

	c.DB.Find(&cadb)
	for _, v := range cadb {
		if v.IssuerNameHash == "" {

			// Calculate the IssuerNameHash
			catls, err := tls.X509KeyPair([]byte(v.Cert), []byte(v.Key))
			if err != nil {
				Information.Error = err.Error()
				return Information, err
			}
			cacert, err := x509.ParseCertificate(catls.Certificate[0])
			if err != nil {
				Information.Error = err.Error()
				return Information, err
			}
			h := sha1.New()

			h.Write(cacert.RawIssuer)
			// var store pemutil.Store
			store := make(map[pemutil.BlockType]interface{})

			pemutil.Decode(store, []byte(v.Cert))
			var skid []byte
			for _, pemUtil := range store {
				cert := pemUtil.(*x509.Certificate)
				skid, _ = certutils.CalculateSKID(cert.PublicKey)
			}

			v.IssuerKeyHash = hex.EncodeToString(skid)
			v.IssuerNameHash = hex.EncodeToString(h.Sum(nil))
			c.DB.Save(&v)
		}
	}

	return Information, nil
}

// Paginated return the CA list paginated
func (c CA) Paginated(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	var count int64
	c.DB.Model(&CA{}).Count(&count)
	counter := int(count)

	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		sql, err := vars.Sql(c)
		if err != nil {
			Information.Error = err.Error()
			return Information, errors.New(dbError)
		}
		var cadb []CA
		c.DB.Select(sql.Select).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&cadb)
		Information.Entries = cadb
	}

	return Information, nil
}

// Search for the CA
func (c CA) Search(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	sql, err := vars.Sql(c)
	if err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}
	var count int64
	c.DB.Model(&CA{}).Where(sql.Where.Query, sql.Where.Values...).Count(&count)
	counter := int(count)

	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		var cadb []CA
		c.DB.Select(sql.Select).Where(sql.Where.Query, sql.Where.Values...).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&cadb)
		Information.Entries = cadb
	}

	return Information, nil
}

// FindSCEPProfile search the SCEP Profile by the profile name
func (c *CA) FindSCEPProfile(options []string) ([]Profile, error) {
	var profiledb []Profile
	profile := &Profile{}
	if len(options) >= 1 {
		if ProfileDB := c.DB.Preload("ScepServer").Where("name = ? and `scep_enabled` = ?", options[0], "1").First(&profile).Find(&profile); ProfileDB.Error != nil {
			return profiledb, errors.New(dbError)
		}
		profiledb = append(profiledb, *profile)
		if len(profiledb) == 0 {
			return profiledb, errors.New("Unknow profile.")
		}
	} else {
		c.DB.Preload("ScepServer").Select("id, name, ca_id, ca_name, mail, street_address, organisation, organisational_unit, country, state, locality, postal_code, validity, key_type, key_size, digest, key_usage, extended_key_usage, ocsp_url, p12_mail_password, p12_mail_subject, p12_mail_from, p12_mail_header, p12_mail_footer, scep_enabled, scep_challenge_password, scep_days_before_renewal, days_before_renewal, renewal_mail, days_before_renewal_mail, renewal_mail_subject, renewal_mail_from, renewal_mail_header, renewal_mail_footer, revoked_valid_until, cloud_enabled, cloud_service").Where("`scep_enabled` = ?", "1").First(&profiledb)
	}
	c.SCEPAssociateProfile = profiledb[0].Name

	return profiledb, nil

}

// CA return the CA public key based on the profile name (SCEP)
func (c CA) CA(pass []byte, options ...string) ([]*x509.Certificate, *rsa.PrivateKey, error) {

	var profiledb []Profile

	profiledb, err := c.FindSCEPProfile(options)

	if err != nil {
		return nil, nil, err
	}

	// Proxy the request if a SCEPServer is defined in the profil

	var ca CA

	if CaDB := c.DB.First(&ca, profiledb[0].CaID).Find(&ca); CaDB.Error != nil {
		c.DB.First(&ca)
	}

	catls, err := tls.X509KeyPair([]byte(ca.Cert), []byte(ca.Key))
	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	key, err := certutils.LoadKey([]byte(ca.Key), pass)
	return []*x509.Certificate{cacert}, key, err
}

// CA return the CA public key based on the profile name (SCEP)
func (c CA) CAbyProfile(pass []byte, profilename string) ([]*x509.Certificate, *rsa.PrivateKey, error) {
	profile := &Profile{}
	// var ProfileDB Profile
	if ProfileDB := c.DB.Where("name = ?", profilename).First(&profile).Find(&profile); ProfileDB.Error != nil {
		return nil, nil, ProfileDB.Error
	}

	var ca CA

	if CaDB := c.DB.First(&ca, profile.CaID).Find(&ca); CaDB.Error != nil {
		c.DB.First(&ca)
	}

	catls, err := tls.X509KeyPair([]byte(ca.Cert), []byte(ca.Key))
	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	key, err := certutils.LoadKey([]byte(ca.Key), pass)
	return []*x509.Certificate{cacert}, key, err
}

// Put create the public key in the DB (SCEP)
func (c CA) Put(cn string, crt *x509.Certificate, options ...string) error {

	attributeMap := certutils.GetDNFromCert(crt.Subject)

	publicKey := new(bytes.Buffer)

	pem.Encode(publicKey, &pem.Block{Type: "CERTIFICATE", Bytes: crt.Raw})

	profiledb, err := c.FindSCEPProfile(options)

	if err != nil {
		return err
	}

	var ca CA

	if CaDB := c.DB.First(&ca, profiledb[0].CaID).Find(&ca); CaDB.Error != nil {
		c.DB.First(&ca)
	}
	notFalse := true
	var IPAddresses []string
	for _, IP := range crt.IPAddresses {
		IPAddresses = append(IPAddresses, IP.String())
	}

	if err := c.DB.Create(&Cert{Cn: cn, Ca: ca, CaName: ca.Cn, ProfileName: profiledb[0].Name, SerialNumber: crt.SerialNumber.String(), Mail: strings.Join(crt.EmailAddresses, ","), StreetAddress: attributeMap["streetAddress"], Organisation: attributeMap["O"], OrganisationalUnit: attributeMap["OU"], Country: attributeMap["C"], State: attributeMap["ST"], Locality: attributeMap["L"], PostalCode: attributeMap["postalCode"], DNSNames: strings.Join(crt.DNSNames, ","), IPAddresses: strings.Join(IPAddresses, ","), Profile: profiledb[0], Key: "", Cert: publicKey.String(), ValidUntil: crt.NotAfter, NotBefore: crt.NotBefore, Scep: &notFalse, Subject: crt.Subject.String()}).Error; err != nil {
		return errors.New(dbError)
	}

	return nil
}

// Serial return the serial number
func (c CA) Serial(options ...string) (*big.Int, error) {

	profiledb, err := c.FindSCEPProfile(options)

	if err != nil {
		return nil, err
	}

	return c.FindSerial(profiledb[0])
}

func (c CA) FindSerial(p Profile) (*big.Int, error) {

	ca := &CA{}

	if CaDB := c.DB.First(&ca, p.CaID).Find(&ca); CaDB.Error != nil {
		c.DB.First(&ca)
	}

	var certdb Cert

	var SerialNumber *big.Int

	err := c.DB.Last(&certdb).Where(&ca)
	if err.Error != nil {
		SerialNumber = big.NewInt(1)
	} else {
		SerialNumber = big.NewInt(int64(certdb.ID + 1))
	}

	return SerialNumber, nil

}

func (c CA) HasCN(cn string, allowTime int, cert *x509.Certificate, revokeOldCertificate bool, options ...string) (bool, error) {

	return revokeNeeded(cn, options[0], allowTime, &c.DB)

}

func revokeNeeded(cn string, profile string, allowTime int, c *gorm.DB) (bool, error) {

	var certif Cert
	var CertDB *gorm.DB

	if CertDB = c.Where("Cn = ? AND profile_name = ?", cn, profile).Find(&certif); CertDB.Error != nil {
		// There is no certificate with this CN in the DB
		return true, nil
	}

	if CertDB.RowsAffected == 0 {
		return true, nil
	}
	certif.DB = *c

	store := make(map[pemutil.BlockType]interface{})

	pemutil.Decode(store, []byte(certif.Cert))
	for _, pemUtil := range store {
		cert := pemUtil.(*x509.Certificate)
		if cert.NotAfter.Unix()-int64((time.Duration(allowTime)*24*time.Hour).Seconds()) < time.Now().Unix() || allowTime == 0 {

			params := make(map[string]string)

			params["id"] = strconv.Itoa(int(certif.ID))
			params["reason"] = strconv.Itoa(ocsp.Superseded)
			certif.Revoke(params)
			return true, nil
		}
	}

	return false, errors.New("Certificate with this Subject already exist: " + cn)

}

// SCEP Verify
func (c CA) Verify(m *scep.CSRReqMessage) (bool, error) {
	prof, _ := c.GetProfileByName(c.SCEPAssociateProfile)

	if prof.CloudEnabled == 1 {
		vcloud, err := cloud.Create(c.Ctx, "intune", prof.CloudService)
		if err != nil {
			return false, err
		}
		err = vcloud.ValidateRequest(c.Ctx, m.CSR.Raw)

		if err != nil {
			return false, err
		}
		c.Cloud = vcloud
		return true, nil
	}
	return true, nil
}

func (c CA) FailureNotify(cert *x509.Certificate, m *scep.CSRReqMessage, message string) {
	if c.Cloud != nil {
		c.Cloud.FailureReply(c.Ctx, cert, m.CSR.Raw, message)
	}
}

func (c CA) SuccessNotify(cert *x509.Certificate, m *scep.CSRReqMessage, message string) {
	if c.Cloud != nil {
		c.Cloud.SuccessReply(c.Ctx, cert, m.CSR.Raw, message)
	}
}

func (c CA) GetProfileByName(name string) (*Profile, error) {
	var profiledb []Profile
	c.DB.Select("id, name, ca_id, ca_name, mail, street_address, organisation, organisational_unit, country, state, locality, postal_code, validity, key_type, key_size, digest, key_usage, extended_key_usage, ocsp_url, p12_mail_password, p12_mail_subject, p12_mail_from, p12_mail_header, p12_mail_footer, scep_enabled, scep_challenge_password, scep_days_before_renewal, days_before_renewal, cloud_enabled, cloud_service").Where("name = ?", name).First(&profiledb)

	return &profiledb[0], nil
}

func (c CA) Resign(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var cadb []CA
	var err error
	if val, ok := params["id"]; ok {
		if err = c.DB.First(&cadb, val).Error; err != nil {
			Information.Error = err.Error()
			return Information, err
		}

	}

	Information.Entries = cadb

	block, _ := pem.Decode([]byte(cadb[0].Key))
	if block == nil {
		log.LoggerWContext(c.Ctx).Error("failed to decode PEM block containing public key")
	}

	var skid []byte
	var keyOut *bytes.Buffer
	keyOut = new(bytes.Buffer)
	var key crypto.PrivateKey
	var pub crypto.PublicKey
	keyOut, skid, pub, key, Information, err = certutils.ExtractPrivateKey(c.KeyType, block, &Information)
	if err != nil {
		return Information, err
	}

	var cadbprevious CA
	var newcadb []CA

	var SerialNumber *big.Int

	if CaDB := c.DB.Last(&cadbprevious); CaDB.Error != nil {
		SerialNumber = big.NewInt(1)
	} else {
		SerialNumber = big.NewInt(int64(cadbprevious.ID + 1))
	}

	Subject := c.MakeSubject()

	ca := &x509.Certificate{
		SerialNumber:          SerialNumber,
		Subject:               Subject,
		NotBefore:             time.Now(),
		NotAfter:              time.Now().AddDate(0, 0, c.Days),
		IsCA:                  true,
		SignatureAlgorithm:    c.Digest,
		ExtKeyUsage:           certutils.Extkeyusage(strings.Split(*c.ExtendedKeyUsage, "|")),
		KeyUsage:              x509.KeyUsage(certutils.Keyusage(strings.Split(*c.KeyUsage, "|"))),
		BasicConstraintsValid: true,
		EmailAddresses:        []string{c.Mail},
		SubjectKeyId:          skid,
		AuthorityKeyId:        skid,
	}

	if len(c.OCSPUrl) > 0 {
		ca.OCSPServer = []string{c.OCSPUrl}
	}

	var caBytes []byte

	switch *c.KeyType {
	case certutils.KEY_RSA:
		caBytes, err = x509.CreateCertificate(rand.Reader, ca, ca, pub, key.(*rsa.PrivateKey))
	case certutils.KEY_ECDSA:
		caBytes, err = x509.CreateCertificate(rand.Reader, ca, ca, pub, key.(*ecdsa.PrivateKey))
	case certutils.KEY_DSA:
		caBytes, err = x509.CreateCertificate(rand.Reader, ca, ca, pub, key.(*dsa.PrivateKey))
	}
	if err != nil {
		return Information, err
	}

	cert := new(bytes.Buffer)
	// Public key
	pem.Encode(cert, &pem.Block{Type: "CERTIFICATE", Bytes: caBytes})

	// Calculate the IssuerNameHash
	catls, err := tls.X509KeyPair([]byte(cert.String()), []byte(keyOut.String()))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	h := sha1.New()

	h.Write(cacert.RawIssuer)

	if err := c.DB.Model(&CA{}).Where("cn = ?", c.Cn).Updates(map[string]interface{}{"Cn": c.Cn, "Mail": c.Mail, "Organisation": c.Organisation, "OrganisationalUnit": c.OrganisationalUnit, "Country": c.Country, "State": c.State, "Locality": c.Locality, "StreetAddress": c.StreetAddress, "PostalCode": c.PostalCode, "KeyType": c.KeyType, "KeySize": c.KeySize, "Digest": c.Digest, "KeyUsage": c.KeyUsage, "ExtendedKeyUsage": c.ExtendedKeyUsage, "Days": c.Days, "Key": keyOut.String(), "Cert": cert.String(), "IssuerKeyHash": hex.EncodeToString(skid), "IssuerNameHash": hex.EncodeToString(h.Sum(nil)), "OCSPUrl": c.OCSPUrl}).Error; err != nil {
		Information.Error = err.Error()
		return Information, errors.New("A database error occured. See log for details.")
	}

	c.DB.Select("id, cn, mail, organisation, organisational_unit, country, state, locality, street_address, postal_code, key_type, key_size, digest, key_usage, extended_key_usage, days, cert, ocsp_url").Where("cn = ?", c.Cn).First(&newcadb)
	Information.Entries = newcadb

	return Information, nil
}

func (c CA) GenerateCSR(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var cadb []CA
	var err error
	if val, ok := params["id"]; ok {
		if err = c.DB.First(&cadb, val).Error; err != nil {
			Information.Status = http.StatusNotFound
			Information.Error = err.Error()
			return Information, err
		}

	}
	catls, err := tls.X509KeyPair([]byte(cadb[0].Cert), []byte(cadb[0].Key))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	Information.Entries = cadb

	template := x509.CertificateRequest{
		Subject:            c.MakeSubject(),
		SignatureAlgorithm: x509.SignatureAlgorithm(x509.SHA256WithRSA),
	}
	csrBuff := new(bytes.Buffer)
	csrBytes, err := x509.CreateCertificateRequest(rand.Reader, &template, catls.PrivateKey)
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	pem.Encode(csrBuff, &pem.Block{Type: "CERTIFICATE REQUEST", Bytes: csrBytes})
	Information.Entries = csrBuff.String()

	if err := c.DB.Model(&CA{}).Where("cn = ?", c.Cn).Updates(map[string]interface{}{"Cn": c.Cn, "Mail": c.Mail, "Organisation": c.Organisation, "OrganisationalUnit": c.OrganisationalUnit, "Country": c.Country, "State": c.State, "Locality": c.Locality, "StreetAddress": c.StreetAddress, "PostalCode": c.PostalCode, "KeyType": c.KeyType, "KeySize": c.KeySize, "Digest": c.Digest, "KeyUsage": c.KeyUsage, "ExtendedKeyUsage": c.ExtendedKeyUsage, "Days": c.Days, "OCSPUrl": c.OCSPUrl}).Error; err != nil {
		Information.Error = err.Error()
		return Information, errors.New("A database error occured. See log for details.")
	}

	return Information, err

}

func (c CA) Update(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var cadb []CA
	var err error
	if val, ok := params["id"]; ok {
		if err = c.DB.First(&cadb, val).Error; err != nil {
			Information.Status = http.StatusNotFound
			Information.Error = err.Error()
			return Information, err
		}
	}
	_, err = tls.X509KeyPair([]byte(c.Cert), []byte(cadb[0].Key))

	if err != nil {
		Information.Error = err.Error()
		Information.Status = http.StatusUnprocessableEntity
		return Information, nil
	}
	cadb[0].Cert = c.Cert
	c.DB.Save(&cadb[0])
	Information.Entries = cadb[0]
	return Information, err
}

// EST
func (c CA) CACerts(ctx context.Context, aps string, r *http.Request) ([]*x509.Certificate, error) {
	var certs []*x509.Certificate
	catls, err := tls.X509KeyPair([]byte(c.Cert), []byte(c.Key))
	if err != nil {
		log.LoggerWContext(c.Ctx).Error(err.Error())
	}
	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	if err != nil {
		log.LoggerWContext(c.Ctx).Error(err.Error())
	}
	certs = append(certs, cacert)
	return certs, nil
}

// Profile section
func NewProfileModel(pfpki *types.Handler) *Profile {
	Profile := &Profile{}

	Profile.DB = *pfpki.DB
	Profile.Ctx = *pfpki.Ctx

	return Profile
}

func (p Profile) New() (types.Info, error) {

	var profiledb []Profile

	var err error
	Information := types.Info{}
	switch *p.KeyType {
	case certutils.KEY_RSA:
		if p.KeySize < 2048 {
			err = errors.New("invalid private key size, should be at least 2048")
			Information.Error = err.Error()
			return Information, err
		}
	case certutils.KEY_ECDSA:
		if !(p.KeySize == 256 || p.KeySize == 384 || p.KeySize == 521) {
			err = errors.New("invalid private key size, should be 256 or 384 or 521")
			Information.Error = err.Error()
			return Information, err
		}
	case certutils.KEY_DSA:
		if !(p.KeySize == 1024 || p.KeySize == 2048 || p.KeySize == 3072) {
			err = errors.New("invalid private key size, should be 1024 or 2048 or 3072")
			Information.Error = err.Error()
			return Information, err
		}
	default:
		return Information, errors.New("KeyType unsupported")

	}

	ca := &CA{}

	if CaDB := p.DB.First(&ca, p.CaID).Find(&ca); CaDB.Error != nil {
		Information.Error = CaDB.Error.Error()
		return Information, CaDB.Error
	}

	scepserver := &SCEPServer{}
	// Choose the default scep server in the db
	if p.ScepServerID == 0 {
		p.ScepServerID = 1
	}

	if ScepServerDB := p.DB.First(&scepserver, p.ScepServerID).Find(&scepserver); ScepServerDB.Error != nil {
		Information.Error = ScepServerDB.Error.Error()
		return Information, ScepServerDB.Error
	}

	profile := Profile{Name: p.Name, Ca: *ca, CaID: p.CaID, CaName: ca.Cn, Mail: p.Mail, StreetAddress: p.StreetAddress, Organisation: p.Organisation, OrganisationalUnit: p.OrganisationalUnit, Country: p.Country, State: p.State, Locality: p.Locality, PostalCode: p.PostalCode, Validity: p.Validity, KeyType: p.KeyType, KeySize: p.KeySize, Digest: p.Digest, KeyUsage: p.KeyUsage, ExtendedKeyUsage: p.ExtendedKeyUsage, OCSPUrl: p.OCSPUrl, P12MailPassword: p.P12MailPassword, P12MailSubject: p.P12MailSubject, P12MailFrom: p.P12MailFrom, P12MailHeader: p.P12MailHeader, P12MailFooter: p.P12MailFooter, SCEPEnabled: p.SCEPEnabled, SCEPChallengePassword: p.SCEPChallengePassword, SCEPDaysBeforeRenewal: p.SCEPDaysBeforeRenewal, DaysBeforeRenewal: p.DaysBeforeRenewal, RenewalMail: p.RenewalMail, DaysBeforeRenewalMail: p.DaysBeforeRenewalMail, RenewalMailSubject: p.RenewalMailSubject, RenewalMailFrom: p.RenewalMailFrom, RenewalMailHeader: p.RenewalMailHeader, RenewalMailFooter: p.RenewalMailFooter, RevokedValidUntil: p.RevokedValidUntil, CloudEnabled: p.CloudEnabled, CloudService: p.CloudService, ScepServerEnabled: p.SCEPEnabled, ScepServerID: p.ScepServerID, ScepServer: p.ScepServer}

	if err := p.DB.Create(&profile).Error; err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}
	p.DB.Select("id, name, ca_id, ca_name, mail, street_address, organisation, organisational_unit, country, state, locality, postal_code, validity, key_type, key_size, digest, key_usage, extended_key_usage, ocsp_url, p12_mail_password, p12_mail_subject, p12_mail_from, p12_mail_header, p12_mail_footer, scep_enabled, scep_challenge_password, scep_days_before_renewal, days_before_renewal, renewal_mail, days_before_renewal_mail, renewal_mail_subject, renewal_mail_from, renewal_mail_header, renewal_mail_footer, revoked_valid_until, cloud_enabled, cloud_service, scep_server_enabled, scep_server_id").Where("name = ?", p.Name).First(&profiledb)
	Information.Entries = profiledb

	return Information, nil
}

func (p Profile) Update(params map[string]string) (types.Info, error) {

	var profiledb []Profile
	Information := types.Info{}
	scepserver := &SCEPServer{}

	profile := &Profile{}

	// Choose the default scep server in the db
	if p.ScepServerID == 0 {
		p.ScepServerID = 1
	}

	if ScepServerDB := p.DB.First(&scepserver, p.ScepServerID).Find(&scepserver); ScepServerDB.Error != nil {
		Information.Error = ScepServerDB.Error.Error()
		return Information, ScepServerDB.Error
	}

	if val, ok := params["id"]; ok {
		if ProfileDB := p.DB.First(&profile, val).Find(&profile); ProfileDB.Error != nil {
			Information.Error = ProfileDB.Error.Error()
			return Information, ProfileDB.Error
		}
	} else {
		if ProfileDB := p.DB.Where("name = ?", p.Name).First(&profile).Find(&profile); ProfileDB.Error != nil {
			Information.Error = ProfileDB.Error.Error()
			return Information, ProfileDB.Error
		}
	}

	fieldsToExtract := []string{"Mail", "Organisation", "OrganisationalUnit", "Country", "State", "Locality", "StreetAddress", "PostalCode", "Validity", "KeyUsage", "ExtendedKeyUsage", "OCSPUrl", "P12MailPassword", "P12MailSubject", "P12MailFrom", "P12MailHeader", "P12MailFooter", "SCEPEnabled", "SCEPChallengePassword", "SCEPDaysBeforeRenewal", "DaysBeforeRenewal", "RenewalMail", "DaysBeforeRenewalMail", "RenewalMailSubject", "RenewalMailFrom", "RenewalMailHeader", "RenewalMailFooter", "RevokedValidUntil", "CloudEnabled", "CloudService", "ScepServerEnabled"}

	v := reflect.ValueOf(p)
	typeOfS := v.Type()
	for i := 0; i < v.NumField(); i++ {
		if contains(fieldsToExtract, typeOfS.Field(i).Name) {
			profile = profile.setProperty(typeOfS.Field(i).Name, v.Field(i).Interface())
		}
	}

	profile.ScepServer = *scepserver
	profile.SCEPEnabled = p.SCEPEnabled

	p.DB.Save(&profile)

	profiledb = append(profiledb, p)
	Information.Entries = profiledb

	return Information, nil
}

func (p *Profile) setProperty(propName string, propValue interface{}) *Profile {
	reflect.ValueOf(p).Elem().FieldByName(propName).Set(reflect.ValueOf(propValue))
	return p
}

func contains(s []string, str string) bool {
	for _, v := range s {
		if v == str {
			return true
		}
	}

	return false
}

func (p Profile) GetByID(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var profiledb []Profile
	if val, ok := params["id"]; ok {
		allFields := strings.Join(sql.SqlFields(p)[:], ",")
		p.DB.Select(allFields).Where("`id` = ?", val).First(&profiledb)
	}
	Information.Entries = profiledb

	return Information, nil
}

func (p Profile) Paginated(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	var count int64
	p.DB.Model(&Profile{}).Count(&count)
	counter := int(count)

	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		sql, err := vars.Sql(p)
		if err != nil {
			Information.Error = err.Error()
			return Information, errors.New(dbError)
		}
		var profiledb []Profile
		p.DB.Select(sql.Select).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&profiledb)
		Information.Entries = profiledb
	}

	return Information, nil
}

func (p Profile) Search(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	sql, err := vars.Sql(p)
	if err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}
	var count int64
	p.DB.Model(&Profile{}).Where(sql.Where.Query, sql.Where.Values...).Count(&count)
	counter := int(count)
	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		var profiledb []Profile
		p.DB.Select(sql.Select).Where(sql.Where.Query, sql.Where.Values...).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&profiledb)
		Information.Entries = profiledb
	}

	return Information, nil
}

func NewCertModel(pfpki *types.Handler) *Cert {
	Cert := &Cert{}

	Cert.DB = *pfpki.DB
	Cert.Ctx = *pfpki.Ctx

	return Cert
}

func (c Cert) New() (types.Info, error) {
	Information := types.Info{}
	Information.Status = http.StatusUnprocessableEntity
	// Find the profile
	var prof Profile
	if profDB := c.DB.Preload("Ca").First(&prof, c.ProfileID); profDB.Error != nil {
		Information.Error = profDB.Error.Error()
		return Information, errors.New(dbError)
	}

	// Check if the certificate is allowed to be revoked
	_, err := revokeNeeded(c.Cn, prof.Name, prof.DaysBeforeRenewal, &c.DB)
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	// Load the certificates from the database
	catls, err := tls.X509KeyPair([]byte(prof.Ca.Cert), []byte(prof.Ca.Key))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	var newcertdb []Cert
	var SerialNumber *big.Int

	SerialNumber = big.NewInt(int64(prof.Ca.SerialNumber))
	prof.Ca.SerialNumber = prof.Ca.SerialNumber + 1
	prof.Ca.DB = c.DB
	prof.Ca.DB.Save(prof.Ca)
	keyOut, pub, _, err := certutils.GenerateKey(*prof.KeyType, prof.KeySize)

	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	skid, err := certutils.CalculateSKID(pub)
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	Subject := c.MakeSubject()

	NotAfter := time.Now().AddDate(0, 0, prof.Validity)

	// Prepare certificate
	cert := &x509.Certificate{
		SerialNumber:       SerialNumber,
		Subject:            Subject,
		NotBefore:          time.Now(),
		NotAfter:           NotAfter,
		SignatureAlgorithm: prof.Digest,
		ExtKeyUsage:        certutils.Extkeyusage(strings.Split(*prof.ExtendedKeyUsage, "|")),
		KeyUsage:           x509.KeyUsage(certutils.Keyusage(strings.Split(*prof.KeyUsage, "|"))),
		SubjectKeyId:       skid,
	}

	if len(prof.OCSPUrl) > 0 {
		cert.OCSPServer = []string{prof.OCSPUrl}
	}

	Email := ""
	if len(prof.Mail) > 0 {
		Email = prof.Mail
	}
	if len(c.Mail) > 0 {
		Email = c.Mail
	}
	if len(Email) > 0 {
		for _, mail := range strings.Split(Email, ",") {
			cert.EmailAddresses = append(cert.EmailAddresses, mail)
		}
	}

	if len(c.DNSNames) > 0 {
		for _, dns := range strings.Split(c.DNSNames, ",") {
			cert.DNSNames = append(cert.DNSNames, dns)
		}
	}
	var IPAddresses []string
	if len(c.IPAddresses) > 0 {
		for _, ip := range strings.Split(c.IPAddresses, ",") {
			if net.ParseIP(ip) == nil {
				fmt.Printf("IP Address: %s - Invalid\n", ip)
			} else {
				IPAddresses = append(IPAddresses, ip)
				cert.IPAddresses = append(cert.IPAddresses, net.ParseIP(ip))
			}
		}
	}

	// Sign the certificate
	certByte, err := x509.CreateCertificate(rand.Reader, cert, cacert, pub, catls.PrivateKey)

	certBuff := new(bytes.Buffer)

	// Public key
	pem.Encode(certBuff, &pem.Block{Type: "CERTIFICATE", Bytes: certByte})

	if err := c.DB.Create(&Cert{Cn: c.Cn, Ca: prof.Ca, CaName: prof.Ca.Cn, ProfileName: prof.Name, SerialNumber: SerialNumber.String(), DNSNames: c.DNSNames, IPAddresses: strings.Join(IPAddresses, ","), Mail: Email, StreetAddress: strings.Join(Subject.StreetAddress, ""), Organisation: strings.Join(Subject.Organization, ""), OrganisationalUnit: strings.Join(Subject.OrganizationalUnit, ""), Country: strings.Join(Subject.Country, ""), State: strings.Join(Subject.Province, ""), Locality: strings.Join(Subject.Locality, ""), PostalCode: strings.Join(Subject.PostalCode, ""), Profile: prof, Key: keyOut.String(), Cert: certBuff.String(), ValidUntil: cert.NotAfter, NotBefore: cert.NotBefore, Subject: Subject.String()}).Error; err != nil {
		Information.Error = err.Error()
		Information.Status = http.StatusConflict
		return Information, errors.New(dbError)
	}

	c.DB.Select("id, cn, mail, street_address, organisation, organisational_unit, country, state, locality, postal_code, cert, profile_id, profile_name, ca_name, ca_id, valid_until, serial_number, dns_names, ip_addresses").Where("cn = ? AND profile_name = ?", c.Cn, prof.Name).First(&newcertdb)
	Information.Entries = newcertdb
	Information.Serial = SerialNumber.String()

	return Information, nil
}

func (c Cert) GetByID(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var certdb []Cert
	allFields := strings.Join(sql.SqlFields(c)[:], ",")
	if val, ok := params["id"]; ok {
		c.DB.Select(allFields).Where("`id` = ?", val).First(&certdb)
	}
	if val, ok := params["cn"]; ok {
		c.DB.Select(allFields).Where("`cn` = ?", val).First(&certdb)
	}

	Information.Entries = certdb

	return Information, nil
}

func (c Cert) Paginated(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	var count int64
	c.DB.Model(&Cert{}).Count(&count)
	counter := int(count)
	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		sql, err := vars.Sql(c)
		if err != nil {
			Information.Error = err.Error()
			return Information, errors.New(dbError)
		}
		var certdb []Cert
		c.DB.Select(sql.Select).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&certdb)
		Information.Entries = certdb
	}

	return Information, nil
}

func (c Cert) Search(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	sql, err := vars.Sql(c)
	if err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}
	var count int64
	c.DB.Model(&Cert{}).Where(sql.Where.Query, sql.Where.Values...).Count(&count)
	counter := int(count)
	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		var certdb []Cert
		c.DB.Select(sql.Select).Where(sql.Where.Query, sql.Where.Values...).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&certdb)
		Information.Entries = certdb
	}

	return Information, nil
}

func (c Cert) Download(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	// Find the Cert
	var cert Cert

	if profile, ok := params["profile"]; ok {
		if val, ok := params["cn"]; ok {
			if CertDB := c.DB.Preload("Ca").Where("Cn = ? AND profile_id = ?", val, profile).Find(&cert); CertDB.Error != nil {
				Information.Error = CertDB.Error.Error()
				return Information, errors.New(dbError)
			}
		}
		if val, ok := params["id"]; ok {
			if CertDB := c.DB.Preload("Ca").Where("Id = ? AND profile_id = ?", val, profile).Find(&cert); CertDB.Error != nil {
				Information.Error = CertDB.Error.Error()
				return Information, errors.New(dbError)
			}
		}
	} else {
		if val, ok := params["id"]; ok {
			if CertDB := c.DB.Preload("Ca").First(&cert, val); CertDB.Error != nil {
				Information.Error = CertDB.Error.Error()
				return Information, errors.New(dbError)
			}
		}
	}

	// Load the certificates from the database
	certtls, err := tls.X509KeyPair([]byte(cert.Cert), []byte(cert.Key))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	// Find the profile
	var prof Profile
	if profDB := c.DB.Where("Name = ?", cert.ProfileName).Find(&prof); profDB.Error != nil {
		Information.Error = profDB.Error.Error()
		return Information, errors.New(dbError)
	}

	certificate, err := x509.ParseCertificate(certtls.Certificate[0])
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	// Load the certificates from the database
	catls, err := tls.X509KeyPair([]byte(cert.Ca.Cert), []byte(cert.Ca.Key))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	var CaCert []*x509.Certificate

	CaCert = append(CaCert, cacert)

	var password string
	if val, ok := params["password"]; ok {
		password = val
	} else {
		password = certutils.GeneratePassword()
	}
	Information.Password = password

	pkcs12, err := pkcs12.Encode(certutils.PRNG, certtls.PrivateKey, certificate, CaCert, password)

	if _, ok := params["password"]; ok {
		Information.Raw = pkcs12
		Information.ContentType = "application/x-pkcs12"
	} else {
		Information, err = emailcert(c.Ctx, cert, prof, pkcs12, password)
	}

	return Information, err
}

func (c Cert) Revoke(params map[string]string) (types.Info, error) {

	Information := types.Info{}
	// Find the Cert
	var cert Cert

	reason := params["reason"]

	if profile, ok := params["profile"]; ok {
		if id, ok := params["id"]; ok {
			if CertDB := c.DB.Preload("Ca").Where("id = ? AND profile_id = ?", id, profile).Find(&cert); CertDB.Error != nil {
				Information.Error = CertDB.Error.Error()
				return Information, CertDB.Error
			}
		}
		if cn, ok := params["cn"]; ok {
			if CertDB := c.DB.Preload("Ca").Where("cn = ? AND profile_id = ?", cn, profile).Find(&cert); CertDB.Error != nil {
				Information.Error = CertDB.Error.Error()
				return Information, CertDB.Error
			}
		}
	} else {
		if id, ok := params["id"]; ok {
			if CertDB := c.DB.Preload("Ca").Where("id = ?", id).Find(&cert); CertDB.Error != nil {
				Information.Error = CertDB.Error.Error()
				return Information, CertDB.Error
			}
		}
	}

	// Find the Profile
	var profile Profile

	error := c.DB.Model(&profile).Where(&cert)
	if error.Error != nil {
		Information.Error = error.Error.Error()
		return Information, error.Error
	}

	intreason, err := strconv.Atoi(reason)
	if err != nil {
		Information.Error = "Reason unsupported"
		return Information, errors.New("Reason unsupported")
	}
	RevokeDate := time.Now().AddDate(0, 0, profile.RevokedValidUntil)
	if err := c.DB.Create(&RevokedCert{Cn: cert.Cn, Mail: cert.Mail, Ca: cert.Ca, CaID: cert.CaID, CaName: cert.CaName, StreetAddress: cert.StreetAddress, Organisation: cert.Organisation, OrganisationalUnit: cert.OrganisationalUnit, Country: cert.Country, State: cert.State, Locality: cert.Locality, PostalCode: cert.Locality, Key: cert.Key, Cert: cert.Cert, Profile: profile, ProfileID: cert.ProfileID, ProfileName: cert.ProfileName, ValidUntil: cert.ValidUntil, NotBefore: cert.NotBefore, Date: cert.Date, Revoked: RevokeDate, CRLReason: intreason, SerialNumber: cert.SerialNumber, DNSNames: cert.DNSNames, IPAddresses: cert.IPAddresses, Subject: cert.Subject}).Error; err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	if err := c.DB.Unscoped().Delete(&cert).Error; err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	return Information, nil
}

func (c Cert) CheckRenewal(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var certdb []Cert

	if CertDB := c.DB.Where("alert <> ?", 1).Find(&certdb); CertDB.Error != nil {
		Information.Error = CertDB.Error.Error()
		return Information, CertDB.Error
	}

	for _, v := range certdb {
		// Find the profile
		var prof Profile
		if profDB := c.DB.First(&prof, v.ProfileID); profDB.Error != nil {
			Information.Error = profDB.Error.Error()
			return Information, errors.New(dbError)
		}
		// Revoke due certificate
		if time.Now().Unix() > v.ValidUntil.Unix() {
			params := make(map[string]string)

			params["id"] = strconv.Itoa(int(v.ID))
			params["reason"] = strconv.Itoa(ocsp.Superseded)
			c.Revoke(params)
		}
		if prof.RenewalMail == 1 {
			if *v.Scep == false {
				if v.ValidUntil.Unix()-int64((time.Duration(prof.DaysBeforeRenewalMail)*24*time.Hour).Seconds()) < time.Now().Unix() {
					emailRenewal(c.Ctx, v, prof)
					notfalse := true
					v.Alert = &notfalse
					c.DB.Save(&v)
				}
			}
		}
	}

	return Information, nil
}

func (c Cert) Resign(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var certdb []Cert
	var err error
	//Search the existing cert in the db
	if val, ok := params["id"]; ok {
		if err = c.DB.Preload("Ca").Preload("Profile").First(&certdb, val).Error; err != nil {
			Information.Error = err.Error()
			return Information, err
		}
	}

	catls, err := tls.X509KeyPair([]byte(certdb[0].Ca.Cert), []byte(certdb[0].Ca.Key))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	Information.Entries = certdb

	// Decode the private key
	block, _ := pem.Decode([]byte(certdb[0].Key))
	if block == nil {
		log.LoggerWContext(c.Ctx).Error("failed to decode PEM block containing public key")
	}

	var skid []byte
	var keyOut *bytes.Buffer
	keyOut = new(bytes.Buffer)
	var pub crypto.PublicKey

	keyOut, skid, pub, _, Information, err = certutils.ExtractPrivateKey(certdb[0].Profile.KeyType, block, &Information)
	if err != nil {
		return Information, err
	}

	// keyOut contain the private key
	var certdbprevious Cert
	var newcertdb []Cert

	//Calculate the serial number to assign
	var SerialNumber *big.Int

	if CertDB := c.DB.Last(&certdbprevious); CertDB.Error != nil {
		SerialNumber = big.NewInt(1)
	} else {
		SerialNumber = big.NewInt(int64(certdbprevious.ID + 1))
	}

	Subject := certdb[0].MakeSubject()

	cert := &x509.Certificate{
		SerialNumber:       SerialNumber,
		Subject:            Subject,
		NotBefore:          time.Now(),
		NotAfter:           time.Now().AddDate(0, 0, certdb[0].Profile.Validity),
		SignatureAlgorithm: certdb[0].Profile.Digest,
		ExtKeyUsage:        certutils.Extkeyusage(strings.Split(*certdb[0].Profile.ExtendedKeyUsage, "|")),
		KeyUsage:           x509.KeyUsage(certutils.Keyusage(strings.Split(*certdb[0].Profile.KeyUsage, "|"))),
		SubjectKeyId:       skid,
	}
	//Overload certificate attributes
	if len(c.Profile.OCSPUrl) > 0 {
		cert.OCSPServer = []string{c.Profile.OCSPUrl}
	}

	Email := ""
	if len(certdb[0].Profile.Mail) > 0 {
		Email = certdb[0].Profile.Mail
	}
	if len(c.Mail) > 0 {
		Email = c.Mail
	}
	if len(Email) > 0 {
		for _, mail := range strings.Split(Email, ",") {
			cert.EmailAddresses = append(cert.EmailAddresses, mail)
		}
	}

	if len(c.DNSNames) > 0 {
		for _, dns := range strings.Split(c.DNSNames, ",") {
			cert.DNSNames = append(cert.DNSNames, dns)
		}
	}
	var IPAddresses []string
	if len(c.IPAddresses) > 0 {
		for _, ip := range strings.Split(c.IPAddresses, ",") {
			if net.ParseIP(ip) == nil {
				fmt.Printf("IP Address: %s - Invalid\n", ip)
			} else {
				IPAddresses = append(IPAddresses, ip)
				cert.IPAddresses = append(cert.IPAddresses, net.ParseIP(ip))
			}
		}
	}

	var certBytes []byte

	switch *certdb[0].Profile.KeyType {
	case certutils.KEY_RSA:
		certBytes, err = x509.CreateCertificate(rand.Reader, cert, cacert, pub, catls.PrivateKey.(*rsa.PrivateKey))
	case certutils.KEY_ECDSA:
		certBytes, err = x509.CreateCertificate(rand.Reader, cert, cacert, pub, catls.PrivateKey.(*ecdsa.PrivateKey))
	case certutils.KEY_DSA:
		certBytes, err = x509.CreateCertificate(rand.Reader, cert, cacert, pub, catls.PrivateKey.(*dsa.PrivateKey))
	}
	if err != nil {
		return Information, err
	}

	certBuff := new(bytes.Buffer)
	// Public key
	pem.Encode(certBuff, &pem.Block{Type: "CERTIFICATE", Bytes: certBytes})

	h := sha1.New()

	h.Write(cacert.RawIssuer)
	if err := c.DB.Model(&Cert{}).Where("cn = ?", c.Cn).Updates(map[string]interface{}{"Cn": c.Cn, "Ca": certdb[0].Ca, "CaName": certdb[0].Ca.Cn, "ProfileName": certdb[0].Profile.Name, "SerialNumber": SerialNumber.String(), "DNSNames": cert.DNSNames, "IPAddresses": strings.Join(IPAddresses, ","), "Mail": Email, "StreetAddress": cert.Subject.StreetAddress, "Organisation": cert.Subject.Organization, "OrganisationalUnit": cert.Subject.OrganizationalUnit, "Country": cert.Subject.Country, "State": cert.Subject.Province, "Locality": cert.Subject.Locality, "PostalCode": cert.Subject.PostalCode, "Profile": certdb[0].Profile, "Key": keyOut.String(), "Cert": certBuff.String(), "ValidUntil": cert.NotAfter, "NotBefore": cert.NotBefore, "Subject": cert.Subject.String()}).Error; err != nil {
		Information.Error = err.Error()
		Information.Status = http.StatusConflict
		return Information, errors.New(dbError)
	}

	c.DB.Select("id, cn, mail, street_address, organisation, organisational_unit, country, state, locality, postal_code, cert, profile_id, profile_name, ca_name, ca_id, valid_until, serial_number, dns_names, ip_addresses").Where("cn = ? AND profile_name = ?", c.Cn, certdb[0].ProfileName).First(&newcertdb)
	Information.Entries = newcertdb
	Information.Serial = SerialNumber.String()

	return Information, nil
}

func (c Cert) MakeSubject() pkix.Name {
	var Subject pkix.Name
	Subject.CommonName = c.Cn

	//Overload certificate attributes if exist
	Organization := ""
	if len(c.Profile.Organisation) > 0 {
		Organization = c.Profile.Organisation
	}
	if len(c.Organisation) > 0 {
		Organization = c.Organisation
	}
	if len(Organization) > 0 {
		Subject.Organization = []string{Organization}
	}

	Country := ""
	if len(c.Profile.Country) > 0 {
		Country = c.Profile.Country
	}
	if len(c.Country) > 0 {
		Country = c.Country
	}
	if len(Country) > 0 {
		Subject.Country = []string{Country}
	}

	Province := ""
	if len(c.Profile.State) > 0 {
		Province = c.Profile.State
	}
	if len(c.State) > 0 {
		Province = c.State
	}
	if len(Province) > 0 {
		Subject.Province = []string{Province}
	}

	Locality := ""
	if len(c.Profile.Locality) > 0 {
		Locality = c.Profile.Locality
	}
	if len(c.Locality) > 0 {
		Locality = c.Locality
	}
	if len(Locality) > 0 {
		Subject.Locality = []string{Locality}
	}

	StreetAddress := ""
	if len(c.Profile.StreetAddress) > 0 {
		StreetAddress = c.Profile.StreetAddress
	}
	if len(c.StreetAddress) > 0 {
		StreetAddress = c.StreetAddress
	}
	if len(StreetAddress) > 0 {
		Subject.StreetAddress = []string{StreetAddress}
	}

	PostalCode := ""
	if len(c.Profile.PostalCode) > 0 {
		PostalCode = c.Profile.PostalCode
	}
	if len(c.PostalCode) > 0 {
		PostalCode = c.PostalCode
	}
	if len(PostalCode) > 0 {
		Subject.PostalCode = []string{PostalCode}
	}
	return Subject
}

func NewRevokedCertModel(pfpki *types.Handler) *RevokedCert {
	RevokedCert := &RevokedCert{}

	RevokedCert.DB = *pfpki.DB
	RevokedCert.Ctx = *pfpki.Ctx

	return RevokedCert
}

func (c RevokedCert) GetByID(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var revokedcertdb []RevokedCert
	if val, ok := params["id"]; ok {
		allFields := strings.Join(sql.SqlFields(c)[:], ",")
		c.DB.Select(allFields).Where("`id` = ?", val).First(&revokedcertdb)
	}
	Information.Entries = revokedcertdb

	return Information, nil
}

func (c RevokedCert) Paginated(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	var count int64
	c.DB.Model(&RevokedCert{}).Count(&count)
	counter := int(count)
	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		sql, err := vars.Sql(c)
		if err != nil {
			Information.Error = err.Error()
			return Information, err
		}
		var revokedcertdb []RevokedCert
		result := c.DB.Select(sql.Select).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&revokedcertdb)
		if result.Error != nil {
			Information.Error = result.Error.Error()
			return Information, err
		}

		Information.Entries = revokedcertdb
	}

	return Information, nil
}

func (c RevokedCert) Search(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	sql, err := vars.Sql(c)
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	var count int64
	c.DB.Model(&Cert{}).Where(sql.Where.Query, sql.Where.Values...).Count(&count)
	counter := int(count)
	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		var revokedcertdb []RevokedCert
		c.DB.Select(sql.Select).Where(sql.Where.Query, sql.Where.Values...).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&revokedcertdb)
		Information.Entries = revokedcertdb
	}

	return Information, nil
}

func NewCsrModel(pfpki *types.Handler) *CSR {
	Csr := &CSR{}

	Csr.DB = *pfpki.DB
	Csr.Ctx = *pfpki.Ctx

	return Csr
}

func (csr CSR) New(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	Information.Status = http.StatusUnprocessableEntity
	// Find the profile
	var prof Profile
	if val, ok := params["id"]; ok {

		if profDB := csr.DB.First(&prof, val); profDB.Error != nil {
			Information.Error = profDB.Error.Error()
			return Information, errors.New(dbError)
		}
	} else {
		return Information, errors.New("Missing the profile id in the url")

	}
	attributes := ProfileAttributes(prof)
	// Find the CA
	var ca CA
	if CaDB := csr.DB.First(&ca, prof.CaID).Find(&ca); CaDB.Error != nil {
		Information.Error = CaDB.Error.Error()
		return Information, errors.New(dbError)
	}

	// Read the CSR here
	var err error
	re := regexp.MustCompile(`(\s|\n)`)

	stringCSR := strings.Trim(csr.Csr, "-----BEGIN CERTIFICATE REQUEST-----")
	stringCSR = strings.Trim(stringCSR, "-----END CERTIFICATE REQUEST-----")
	stringCSR = re.ReplaceAllString(stringCSR, "")

	byteCSR := []byte(stringCSR)

	d := make([]byte, base64.StdEncoding.DecodedLen(len(byteCSR)))
	n, err := base64.StdEncoding.Decode(d, byteCSR)

	d = d[:n]

	certRequest, err := x509.ParseCertificateRequest(d)

	id, err := cryptoutil.GenerateSubjectKeyID(certRequest.PublicKey)
	if err != nil {
		return Information, err
	}

	ca.DB = csr.DB

	serial, err := ca.FindSerial(prof)

	if err != nil {
		return Information, err
	}

	Subject := certutils.MakeSubject(certRequest.Subject, attributes)
	Subject.CommonName = certRequest.Subject.CommonName

	ExtKeyUsage := certutils.Extkeyusage(strings.Split(attributes["ExtendedKeyUsage"], "|"))
	KeyUsage := x509.KeyUsage(certutils.Keyusage(strings.Split(attributes["KeyUsage"], "|")))

	// create cert template
	v, _ := strconv.Atoi(attributes["Digest"])
	SignatureAlgorithm := x509.SignatureAlgorithm(v)

	var ExtraExtensions []pkix.Extension

	for _, v := range certRequest.Extensions {
		if v.Id.String() != "2.5.29.37" {
			if v.Id.String() == "2.5.29.17" {
				ext, err := certutils.ForEachSAN(v.Value, attributes)
				if err == nil {
					ExtraExtensions = append(ExtraExtensions, ext)
				}
			} else {
				ExtraExtensions = append(ExtraExtensions, v)
			}
		}

	}

	tmpl := &x509.Certificate{
		SerialNumber:       serial,
		Subject:            Subject,
		NotBefore:          time.Now().Add(-600).UTC(),
		NotAfter:           time.Now().AddDate(0, 0, prof.Validity).UTC(),
		SubjectKeyId:       id,
		KeyUsage:           KeyUsage,
		ExtKeyUsage:        ExtKeyUsage,
		SignatureAlgorithm: SignatureAlgorithm,
		DNSNames:           certRequest.DNSNames,
		EmailAddresses:     certRequest.EmailAddresses,
		IPAddresses:        certRequest.IPAddresses,
		URIs:               certRequest.URIs,
		ExtraExtensions:    ExtraExtensions,
	}

	if len(attributes["OCSPUrl"]) > 0 {
		tmpl.OCSPServer = []string{attributes["OCSPUrl"]}
	}

	if len(attributes["Mail"]) > 0 {
		tmpl.EmailAddresses = []string{attributes["Mail"]}
	}

	// Load the certificates from the database
	catls, err := tls.X509KeyPair([]byte(ca.Cert), []byte(ca.Key))
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	cacert, err := x509.ParseCertificate(catls.Certificate[0])
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	// Sign the certificate
	certByte, err := x509.CreateCertificate(rand.Reader, tmpl, cacert, certRequest.PublicKey, catls.PrivateKey)

	certBuff := new(bytes.Buffer)

	// Public key
	pem.Encode(certBuff, &pem.Block{Type: "CERTIFICATE", Bytes: certByte})

	c := &Cert{}

	c.DB = csr.DB
	c.Ctx = csr.Ctx

	var IPAddresses []string
	for _, IP := range certRequest.IPAddresses {
		IPAddresses = append(IPAddresses, IP.String())
	}

	attributeMap := certutils.GetDNFromCert(Subject)

	certif, err := x509.ParseCertificate(certByte)
	name := certutils.CertName(certif)
	notfalse := true

	if err := c.DB.Create(&Cert{Cn: name, Ca: ca, CaName: ca.Cn, ProfileName: prof.Name, SerialNumber: serial.String(), DNSNames: c.DNSNames, IPAddresses: strings.Join(IPAddresses, ","), Mail: strings.Join(certRequest.EmailAddresses, ","), StreetAddress: attributeMap["streetAddress"], Organisation: attributeMap["O"], OrganisationalUnit: attributeMap["OU"], Country: attributeMap["C"], State: attributeMap["ST"], Locality: attributeMap["L"], PostalCode: attributeMap["postalCode"], Profile: prof, Cert: certBuff.String(), ValidUntil: tmpl.NotAfter, Subject: Subject.String(), Csr: &notfalse}).Error; err != nil {
		Information.Error = err.Error()
		Information.Status = http.StatusConflict
		return Information, errors.New(dbError)
	}
	var newcertdb []Cert
	c.DB.Select("id, cn, mail, street_address, organisation, organisational_unit, country, state, locality, postal_code, cert, profile_id, profile_name, ca_name, ca_id, valid_until, serial_number, dns_names, ip_addresses").Where("subject = ? AND profile_name = ?", Subject.String(), prof.Name).First(&newcertdb)
	Information.Entries = newcertdb
	Information.Serial = serial.String()

	return Information, nil

}

// EmailType strucure
type EmailType struct {
	Header   string
	Footer   string
	Password string
	To       string
	From     string
	Subject  string
	FileName string
	File     []byte
	Template string
}

func emailcert(ctx context.Context, cert Cert, profile Profile, file []byte, password string) (types.Info, error) {
	pfconfigdriver.PfconfigPool.AddStruct(ctx, &pfconfigdriver.Config.PfConf.Alerting)
	alerting := pfconfigdriver.Config.PfConf.Alerting

	mail := EmailType{Header: profile.P12MailHeader, Footer: profile.P12MailFooter}
	if len(profile.P12MailFrom) > 0 {
		mail.From = profile.P12MailFrom
	} else if len(alerting.FromAddr) > 0 {
		mail.From = alerting.FromAddr
	} else {
		name, _ := os.Hostname()
		mail.From = "root@" + name
	}
	mail.To = cert.Mail
	mail.Subject = profile.P12MailSubject
	mail.FileName = cert.Cn
	mail.Template = "emails-pki_certificate.html"
	mail.File = file
	mail.Password = password
	return email(ctx, mail)
}

func emailRenewal(ctx context.Context, cert Cert, profile Profile) (types.Info, error) {
	pfconfigdriver.PfconfigPool.AddStruct(ctx, &pfconfigdriver.Config.PfConf.Alerting)
	alerting := pfconfigdriver.Config.PfConf.Alerting

	mail := EmailType{}

	if len(profile.RenewalMailFrom) > 0 {
		mail.From = profile.RenewalMailFrom
	} else {
		mail.From = alerting.FromAddr
	}

	if len(cert.Mail) > 0 {
		mail.To = cert.Mail
	} else if len(profile.Mail) > 0 {
		mail.To = profile.Mail
	} else if len(alerting.EmailAddr) > 0 {
		mail.To = alerting.EmailAddr
	} else {
		name, _ := os.Hostname()
		mail.From = "root@" + name
	}
	mail.Subject = profile.RenewalMailSubject
	mail.FileName = "Profile Name: " + profile.Name + " Certificate CN: " + cert.Cn
	mail.Template = "emails-renewal_certificate.html"
	mail.Header = profile.RenewalMailHeader
	mail.Footer = profile.RenewalMailFooter

	return email(ctx, mail)
}

func email(ctx context.Context, email EmailType) (types.Info, error) {
	pfconfigdriver.PfconfigPool.AddStruct(ctx, &pfconfigdriver.Config.PfConf.Alerting)
	pfconfigdriver.PfconfigPool.AddStruct(ctx, &pfconfigdriver.Config.PfConf.Advanced)
	alerting := pfconfigdriver.Config.PfConf.Alerting
	advanced := pfconfigdriver.Config.PfConf.Advanced

	Information := types.Info{}

	dict, err := ParseYAMLDict()
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	cat, err := catalog.NewFromMap(dict)
	if err != nil {
		Information.Error = err.Error()
		return Information, err
	}
	message.DefaultCatalog = cat

	m := gomail.NewMessage()

	m.SetHeader("From", email.From)
	m.SetHeader("To", email.To)
	m.SetHeader("Subject", email.Subject)

	lang := language.MustParse(advanced.Language)

	emailContent, err := parseTemplate(email.Template, lang, email)

	m.SetBody("text/html", emailContent)
	if len(email.File) > 0 {
		m.Attach(email.FileName+".p12", gomail.SetCopyFunc(func(w io.Writer) error {
			_, err := w.Write(email.File)
			return err
		}))
	}
	d := gomail.NewDialer(alerting.SMTPServer, alerting.SMTPPort, alerting.SMTPUsername, alerting.SMTPPassword)

	if alerting.SMTPVerifySSL == "disabled" || alerting.SMTPEncryption == "none" {
		d.TLSConfig = &tls.Config{InsecureSkipVerify: true}
	}

	if err := d.DialAndSend(m); err != nil {
		Information.Error = err.Error()
		return Information, err
	}

	return Information, nil
}

func parseTemplate(tplName string, lang language.Tag, data interface{}) (string, error) {
	p := message.NewPrinter(lang)
	fmap := template.FuncMap{
		"translate": p.Sprintf,
	}

	t, err := template.New(tplName).Funcs(fmap).ParseFiles("/usr/local/pf/html/captive-portal/templates/emails/" + tplName)
	if err != nil {
		return "", err
	}

	buf := bytes.NewBuffer([]byte{})
	if err := t.Execute(buf, data); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func ParseYAMLDict() (map[string]catalog.Dictionary, error) {
	dir := "/usr/local/pf/conf/caddy-services/locales"
	files, err := os.ReadDir(dir)
	if err != nil {
		fmt.Println(err)
		return nil, err
	}

	translations := map[string]catalog.Dictionary{}

	for _, f := range files {
		yamlFile, err := os.ReadFile(dir + "/" + f.Name())
		if err != nil {
			return nil, err
		}
		data := map[string]string{}
		err = yaml.Unmarshal(yamlFile, &data)
		if err != nil {
			return nil, err
		}

		lang := strings.Split(f.Name(), ".")[0]

		translations[lang] = &dictionary{Data: data}
	}

	return translations, nil
}

type dictionary struct {
	Data map[string]string
}

func (d *dictionary) Lookup(key string) (data string, ok bool) {
	if _, ok := d.Data[key]; !ok {
		return "", false
	}

	return "\x02" + d.Data[key], true
}

func ProfileAttributes(prof Profile) map[string]string {
	var attributes map[string]string
	attributes = make(map[string]string)

	if len(prof.Organisation) > 0 {
		attributes["Organization"] = prof.Organisation
	}

	if len(prof.OrganisationalUnit) > 0 {
		attributes["OrganizationalUnit"] = prof.OrganisationalUnit
	}

	if len(prof.Country) > 0 {
		attributes["Country"] = prof.Country
	}

	if len(prof.State) > 0 {
		attributes["State"] = prof.State
	}

	if len(prof.Locality) > 0 {
		attributes["Locality"] = prof.Locality
	}

	if len(prof.StreetAddress) > 0 {
		attributes["StreetAddress"] = prof.StreetAddress
	}

	if len(prof.PostalCode) > 0 {
		attributes["PostalCode"] = prof.PostalCode
	}

	if len(*prof.ExtendedKeyUsage) > 0 {
		attributes["ExtendedKeyUsage"] = *prof.ExtendedKeyUsage
	}
	if len(*prof.KeyUsage) > 0 {
		attributes["KeyUsage"] = *prof.KeyUsage
	}

	if len(prof.OCSPUrl) > 0 {
		attributes["OCSPUrl"] = prof.OCSPUrl
	}

	if len(prof.Mail) > 0 {
		attributes["Mail"] = prof.Mail
	}
	if len(prof.Digest.String()) > 0 {
		val := strconv.Itoa(int(prof.Digest))
		attributes["Digest"] = val
	}
	return attributes
}

func NewSCEPServerModel(pfpki *types.Handler) *SCEPServer {
	SCEPServer := &SCEPServer{}

	SCEPServer.DB = *pfpki.DB
	SCEPServer.Ctx = *pfpki.Ctx

	return SCEPServer
}

func (s SCEPServer) New() (types.Info, error) {
	Information := types.Info{}
	var scepserverdb []SCEPServer

	if err := s.DB.Create(&SCEPServer{Name: s.Name, URL: s.URL, SharedSecret: s.SharedSecret}).Error; err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}
	s.DB.Select("id, name, url, shared_secret").Where("name = ?", s.Name).First(&scepserverdb)
	Information.Entries = scepserverdb

	return Information, nil
}

// GetByID retreive the SCEPServer by id
func (s SCEPServer) GetByID(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var scepserverdb []SCEPServer
	if val, ok := params["id"]; ok {
		allFields := strings.Join(sql.SqlFields(s)[:], ",")
		s.DB.Select(allFields).Where("`id` = ?", val).First(&scepserverdb)
	}
	Information.Entries = scepserverdb

	return Information, nil
}

// GetByID retreive the SCEPServer by id
func (s SCEPServer) DelByID(params map[string]string) (types.Info, error) {
	Information := types.Info{}
	var scepserverdb []SCEPServer
	if val, ok := params["id"]; ok {
		s.DB.Delete(&SCEPServer{}, val)
	}
	Information.Entries = scepserverdb
	return Information, nil
}

// Search for the SCEPServer
func (s SCEPServer) Search(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	sql, err := vars.Sql(s)
	if err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}
	var count int64
	s.DB.Model(&SCEPServer{}).Where(sql.Where.Query, sql.Where.Values...).Count(&count)
	counter := int(count)

	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		var scepserverdb []SCEPServer
		s.DB.Select(sql.Select).Where(sql.Where.Query, sql.Where.Values...).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&scepserverdb)
		Information.Entries = scepserverdb
	}

	return Information, nil
}

func (s SCEPServer) Update() (types.Info, error) {
	var scepserverdb []SCEPServer
	Information := types.Info{}
	if err := s.DB.Model(&SCEPServer{}).Where("name = ?", s.Name).Updates(map[string]interface{}{"url": s.URL, "shared_secret": s.SharedSecret}).Error; err != nil {
		Information.Error = err.Error()
		return Information, errors.New(dbError)
	}
	s.DB.Select("id, name, url, shared_secret").Where("name = ?", s.Name).First(&scepserverdb)
	Information.Entries = scepserverdb

	return Information, nil
}

// Paginated return the SCEPServer list paginated
func (s SCEPServer) Paginated(vars sql.Vars) (types.Info, error) {
	Information := types.Info{}
	var count int64
	s.DB.Model(&CA{}).Count(&count)
	counter := int(count)

	Information.TotalCount = counter
	Information.PrevCursor = vars.Cursor
	Information.NextCursor = vars.Cursor + vars.Limit
	if vars.Cursor < counter {
		sql, err := vars.Sql(s)
		if err != nil {
			Information.Error = err.Error()
			return Information, errors.New(dbError)
		}
		var scepserverdb []SCEPServer
		s.DB.Select(sql.Select).Order(sql.Order).Offset(sql.Offset).Limit(sql.Limit).Find(&scepserverdb)
		Information.Entries = scepserverdb
	}

	return Information, nil
}
