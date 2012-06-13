# Implements a simple object containing basic user information retrieved from the
# UVA LDAP server (see http://www.itc.virginia.edu/network/ldap.html)
class UvaLdap
  require 'net/ldap'
  
  # The user's University Computing ID. (LDAP: uid)
  attr_reader :uva_computing_id
  # The user's official surname from administrative records. (LDAP: sn)
  attr_reader :last_name
  # The user's first official name from administrative records. (LDAP: givenname)
  attr_reader :first_name
  # A University building or a U.S. Mail address at which the user can receive printed mail. (LDAP: physicaldeliveryofficename)
  #   OR
  # The official University address for a particular department. This address is for internal mail (Messenger Mail) and for external (U.S.) mail. (LDAP: postaladdress)
  attr_reader :address_1
  # The room number in a particular building in which the user works. (LDAP: roomnumber)
  attr_reader :address_2
  # The user's affiliation with the University as derived from administrative records. (LDAP: affiliation, edupersonprimaryaffiliation, edupersonaffiliation)
  attr_reader :uva_status
  # The office telephone number. (LDAP: telephonenumber, which can contain up to 2 telephone numbers.)
  #   OR
  # Home telephone number for University faculty and staff. (LDAP: homephone)
  #   OR
  # Cellular or other type of mobile phone number (LDAP: mobile)
  attr_reader :phone
  # Fax number for the user. (LDAP: officefax or facsimiletelephonenumber)
  attr_reader :fax
  # The user's primary email address. (LDAP: preferredemailaddress, mailalternateaddress, mail)
  attr_reader :email
  # Title information from the University printed directory for faculty and for staff. (LDAP: title)
  attr_reader :title
  # The department display name in which the user works or the primary school of attendance for students.
  attr_reader :department
  
  
  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------

  # Creates a new UvaLdap object after searching for someone's information by passing 
  # his/her UVA Computing ID to this method.
  def initialize(computing_id)
    treebase = 'o=University of Virginia,c=US'
  
    # Establish a connection to the UVA LDAP server
    ldap = Net::LDAP.new(:host => 'ldap.virginia.edu')
      
    # Set the search criteria to look for the computing id in LDAP.
    search_string = Net::LDAP::Filter.eq('uid', computing_id)
    
    begin
      #Search for the user and retrieve his/her information if found.
      ldap.search(:base => treebase, :filter => search_string) do |entry|
        @uva_computing_id = entry.uid
        @last_name = entry.sn
        @first_name = entry.givenname
        
        # Check one of two fields for an address.
        begin
          @address_1 = entry.physicaldeliveryofficename
        rescue
          begin
            @address_1 = entry.postaladdress
          rescue
            @address_1 = ''
          end
        end
        
        # Check to see if a room number exists
        begin
          @address_2 = entry.roomnumber
        rescue
          @address_2 = ''
        end
        
        # Check for the person's affiliation with the university.
        begin
          @uva_status = entry.affiliation
        rescue
          begin
            @uva_status = entry.edupersonprimaryaffiliation
          rescue
            begin
              @uva_status = entry.edupersonaffiliation
            rescue
              @uva_status = ''
            end
          end
        end
        
        # Take the first phone entry only unless it is empty. If not found then
        # check for a home or mobile number.
        begin
          @phone = entry.telephonenumber[0]
        rescue
          begin
            @phone = entry.homephone
          rescue
            begin
              @phone = entry.mobile
            rescue
              @phone = ''
            end
          end
        end
        
        # fax_number is populated by checking for an existing value in the officefax
        # or facsimiletelephonenumber LDAP fields.
        begin
          @fax = entry.officefax
        rescue
          begin
            @fax = entry.facsimiletelephonenumber
          rescue
            @fax = ''
          end
        end
        
        # Check for an email address in one of the possible LDAP fields.
        begin
          @email = entry.mail
        rescue
          begin
            @email = entry.preferredemailaddress
          rescue
            begin
              @email = entry.mailalternateaddress
            rescue
              @email = ''
            end
          end
        end
        
        # Get the employee's title if it exists
        begin
          @title = entry.title
        rescue
          @title = ''
        end
        
        # Identify the person's department or school if it exists
        begin
          @department = entry.uvadisplaydepartment
        rescue
          begin
            @department = entry.ou
          rescue
            @department = ''
          end
        end
      end # ldap.search
    rescue
      # The LDAP search failed so set all attributes to be empty
      @uva_computing_id = ''
      @last_name = ''
      @first_name = ''
      @address_1 = ''
      @address_2 = ''
      @uva_status = ''
      @phone = ''
      @fax = ''
      @email = ''
      @title = ''
      @department = ''
    end
  end
  
  
  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------
  
  # Determines if the existing LDAP record has all empty/nil field values, i.e. the user was not found in LDAP
  def empty?
    if ((self.uva_computing_id == nil) and (self.last_name == nil) and (self.first_name == nil) and 
        (self.address_1 == nil) and (self.address_2 == nil) and (self.uva_status == nil) and (self.phone == nil) and
        (self.fax == nil) and (self.email == nil) and (self.title == nil) and (self.department == nil))
      return true
    else
      return false
    end
  end
end